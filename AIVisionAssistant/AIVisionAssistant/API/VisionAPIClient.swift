import Foundation

protocol VisionProvider {
    func analyze(imageData: Data, systemPrompt: String, apiKey: String, model: String) async throws -> String
}

enum VisionAPIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case http(status: Int, body: String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key is configured. Open Settings to add one."
        case .invalidResponse:
            return "The AI provider returned an invalid response."
        case let .http(status, body):
            return "AI provider request failed (\(status)): \(body)"
        case .decoding:
            return "The AI provider response could not be decoded."
        }
    }
}

func makeProvider(for provider: AIProvider) -> VisionProvider {
    switch provider {
    case .openAI: return OpenAIProvider()
    case .anthropic: return AnthropicProvider()
    case .gemini: return GeminiProvider()
    }
}

private struct OpenAIRequest: Encodable {
    struct Message: Encodable {
        struct Content: Encodable {
            let type: String
            let text: String?
            let imageURL: ImageURL?

            enum CodingKeys: String, CodingKey {
                case type, text
                case imageURL = "image_url"
            }
        }
        let role: String
        let content: [Content]
    }
    let model: String
    let messages: [Message]
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

private struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable { let content: String? }
        let message: Message
    }
    let choices: [Choice]
}

private struct ImageURL: Encodable {
    let url: String
}

private struct AnthropicRequest: Encodable {
    struct Message: Encodable {
        struct Content: Encodable {
            let type: String
            let text: String?
            let source: Source?
        }
        struct Source: Encodable {
            let type: String
            let mediaType: String
            let data: String
            enum CodingKeys: String, CodingKey {
                case type, data
                case mediaType = "media_type"
            }
        }
        let role: String
        let content: [Content]
    }
    let model: String
    let maxTokens: Int
    let messages: [Message]
    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

private struct AnthropicResponse: Decodable {
    struct Content: Decodable { let text: String? }
    let content: [Content]
}

private struct GeminiRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable {
            let text: String?
            let inlineData: InlineData?
            enum CodingKeys: String, CodingKey {
                case text
                case inlineData = "inline_data"
            }
        }
        let parts: [Part]
    }
    struct InlineData: Encodable {
        let mimeType: String
        let data: String
        enum CodingKeys: String, CodingKey {
            case data
            case mimeType = "mime_type"
        }
    }
    let contents: [Content]
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable { let text: String? }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

private func performRequest<T: Encodable, R: Decodable>(
    url: URL,
    headers: [String: String],
    body: T
) async throws -> R {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw VisionAPIError.invalidResponse
    }
    guard (200...299).contains(httpResponse.statusCode) else {
        throw VisionAPIError.http(
            status: httpResponse.statusCode,
            body: String(data: data, encoding: .utf8) ?? "Unknown error"
        )
    }
    do {
        return try JSONDecoder().decode(R.self, from: data)
    } catch {
        throw VisionAPIError.decoding
    }
}

struct OpenAIProvider: VisionProvider {
    func analyze(imageData: Data, systemPrompt: String, apiKey: String, model: String) async throws -> String {
        let content = [
            OpenAIRequest.Message.Content(type: "text", text: systemPrompt, imageURL: nil),
            OpenAIRequest.Message.Content(
                type: "image_url",
                text: nil,
                imageURL: ImageURL(url: "data:image/png;base64,\(imageData.base64EncodedString())")
            )
        ]
        let body = OpenAIRequest(
            model: model,
            messages: [OpenAIRequest.Message(role: "user", content: content)],
            maxTokens: 1000
        )
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw VisionAPIError.invalidResponse
        }
        let response: OpenAIResponse = try await performRequest(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body
        )
        guard let text = response.choices.first?.message.content, !text.isEmpty else {
            throw VisionAPIError.invalidResponse
        }
        return text
    }
}

struct AnthropicProvider: VisionProvider {
    func analyze(imageData: Data, systemPrompt: String, apiKey: String, model: String) async throws -> String {
        let source = AnthropicRequest.Message.Source(
            type: "base64", mediaType: "image/png", data: imageData.base64EncodedString()
        )
        let content = [
            AnthropicRequest.Message.Content(type: "text", text: systemPrompt, source: nil),
            AnthropicRequest.Message.Content(type: "image", text: nil, source: source)
        ]
        let body = AnthropicRequest(
            model: model,
            maxTokens: 1000,
            messages: [AnthropicRequest.Message(role: "user", content: content)]
        )
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw VisionAPIError.invalidResponse
        }
        let response: AnthropicResponse = try await performRequest(
            url: url,
            headers: ["x-api-key": apiKey, "anthropic-version": "2023-06-01"],
            body: body
        )
        guard let text = response.content.first?.text, !text.isEmpty else {
            throw VisionAPIError.invalidResponse
        }
        return text
    }
}

struct GeminiProvider: VisionProvider {
    func analyze(imageData: Data, systemPrompt: String, apiKey: String, model: String) async throws -> String {
        let parts = [
            GeminiRequest.Content.Part(text: systemPrompt, inlineData: nil),
            GeminiRequest.Content.Part(
                text: nil,
                inlineData: GeminiRequest.InlineData(
                    mimeType: "image/png",
                    data: imageData.base64EncodedString()
                )
            )
        ]
        let body = GeminiRequest(contents: [GeminiRequest.Content(parts: parts)])
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")
        components?.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components?.url else { throw VisionAPIError.invalidResponse }
        let response: GeminiResponse = try await performRequest(url: url, headers: [:], body: body)
        guard let text = response.candidates.first?.content.parts.first?.text, !text.isEmpty else {
            throw VisionAPIError.invalidResponse
        }
        return text
    }
}
