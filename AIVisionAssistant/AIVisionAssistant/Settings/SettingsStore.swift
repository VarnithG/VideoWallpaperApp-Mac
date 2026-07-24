import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    @Published var provider: AIProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: Keys.provider) }
    }
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Keys.model) }
    }
    @Published var systemPrompt: String {
        didSet { UserDefaults.standard.set(systemPrompt, forKey: Keys.systemPrompt) }
    }

    private enum Keys {
        static let provider = "provider"
        static let model = "model"
        static let systemPrompt = "systemPrompt"
    }

    private init() {
        let storedProvider = UserDefaults.standard.string(forKey: Keys.provider)
            .flatMap(AIProvider.init(rawValue:)) ?? .openAI
        provider = storedProvider
        model = UserDefaults.standard.string(forKey: Keys.model) ?? storedProvider.defaultModel
        systemPrompt = UserDefaults.standard.string(forKey: Keys.systemPrompt)
            ?? "Analyze this image and provide a concise solution."
    }
}
