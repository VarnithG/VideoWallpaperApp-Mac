import SwiftUI
import AppKit

struct PanelView: View {
    @ObservedObject private var coordinator = AppCoordinator.shared
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(spacing: 14) {
            Text("AI Vision Assistant")
                .font(.headline)
            Button {
                Task { await coordinator.runCapturePipeline() }
            } label: {
                Label("Capture & Analyze (⌘⇧S)", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(coordinator.isProcessing)

            HStack {
                Text(settings.provider.displayName)
                    .foregroundStyle(.secondary)
                Spacer()
                if coordinator.isProcessing {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack {
                Button("Settings…") {
                    (NSApp.delegate as? AppDelegate)?.openSettings()
                }
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}
