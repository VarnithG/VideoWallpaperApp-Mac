import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var apiKey = ""

    var body: some View {
        Form {
            Picker("Provider", selection: $settings.provider) {
                ForEach(AIProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .onChange(of: settings.provider) { provider in
                settings.model = provider.defaultModel
                apiKey = KeychainHelper.load(account: provider.rawValue) ?? ""
            }

            TextField("Model", text: $settings.model)
            SecureField("API key", text: $apiKey)
                .onChange(of: apiKey) { value in
                    if value.isEmpty {
                        KeychainHelper.delete(account: settings.provider.rawValue)
                    } else {
                        KeychainHelper.save(value, account: settings.provider.rawValue)
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                Text("System prompt")
                TextEditor(text: $settings.systemPrompt)
                    .frame(minHeight: 110)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(.quaternary))
            }

            Text("API keys are stored securely in the macOS Keychain.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 480, height: 390)
        .onAppear {
            apiKey = KeychainHelper.load(account: settings.provider.rawValue) ?? ""
        }
    }
}
