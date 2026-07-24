import AppKit
import SwiftUI

@MainActor
final class PanelController {
    private var panel: NSPanel?

    func toggle(relativeTo statusButton: NSStatusBarButton?) {
        if let panel, panel.isVisible {
            panel.orderOut(nil)
            return
        }

        let panel = makePanel()
        if let buttonWindow = statusButton?.window, let screen = buttonWindow.screen {
            let buttonFrame = buttonWindow.convertToScreen(statusButton?.frame ?? .zero)
            let x = min(max(buttonFrame.midX - panel.frame.width / 2, screen.visibleFrame.minX),
                        screen.visibleFrame.maxX - panel.frame.width)
            panel.setFrameTopLeftPoint(NSPoint(x: x, y: buttonFrame.minY - 6))
        } else {
            panel.center()
        }
        panel.makeKeyAndOrderFront(nil)
    }

    private func makePanel() -> NSPanel {
        if let panel { return panel }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 260),
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "AI Vision Assistant"
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.contentViewController = NSHostingController(rootView: PanelView())
        self.panel = panel
        return panel
    }
}
