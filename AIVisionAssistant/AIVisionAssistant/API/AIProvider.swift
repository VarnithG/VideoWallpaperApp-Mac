import Foundation

enum AIProvider: String, CaseIterable, Identifiable, Codable {
    case openAI
    case anthropic
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .gemini: return "Google Gemini"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o"
        case .anthropic: return "claude-3-5-sonnet-20241022"
        case .gemini: return "gemini-1.5-flash"
        }
    }
}
