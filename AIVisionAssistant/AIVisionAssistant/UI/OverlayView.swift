import SwiftUI
import AppKit

struct OverlayView: View {
    @ObservedObject private var coordinator = AppCoordinator.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Vision Assistant")
                    .font(.headline)
                Spacer()
                if let response = coordinator.lastResponse, !response.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(response, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
                Button {
                    NSApp.keyWindow?.orderOut(nil)
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
            }

            if coordinator.isProcessing {
                ProgressView("Analyzing…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = coordinator.errorMessage {
                ScrollView {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let response = coordinator.lastResponse {
                ScrollView {
                    Text(response)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Text("Capture a screenshot to begin.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(minWidth: 420, minHeight: 520)
    }
}
