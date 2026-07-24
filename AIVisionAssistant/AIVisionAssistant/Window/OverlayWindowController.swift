import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController {
    private var panel: NSPanel?

    func showLoading() {
        AppCoordinator.shared.isProcessing = true
        present()
    }

    func showError(_ message: String) {
        AppCoordinator.shared.errorMessage = message
        present()
    }

    func present() {
        let panel = makePanel()
        position(panel)
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel() -> NSPanel {
        if let panel { return panel }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.nonactivatingPanel, .titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "AI Vision Assistant"
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // SharingType.none keeps this response panel out of screen capture and sharing.
        panel.sharingType = .none
        panel.isReleasedWhenClosed = false
        panel.contentViewController = NSHostingController(rootView: OverlayView())
        self.panel = panel
        return panel
    }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else {
            panel.center()
            return
        }
        let visible = screen.visibleFrame
        let origin = NSPoint(
            x: visible.maxX - panel.frame.width - 20,
            y: visible.maxY - panel.frame.height - 20
        )
        panel.setFrameOrigin(origin)
    }
}
