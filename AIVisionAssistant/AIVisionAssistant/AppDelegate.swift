import AppKit
import SwiftUI
import CoreGraphics

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panelController: PanelController?
    private var settingsWindowController: NSWindowController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "sparkles.rectangle.stack", accessibilityDescription: "AI Vision Assistant")
        item.button?.target = self
        item.button?.action = #selector(togglePanel(_:))
        statusItem = item

        panelController = PanelController()
        let coordinator = AppCoordinator.shared
        let manager = HotkeyManager { [weak coordinator] in
            Task { @MainActor in
                await coordinator?.runCapturePipeline()
            }
        }
        manager.register()
        hotkeyManager = manager

        if CGPreflightScreenCaptureAccess() == false {
            _ = CGRequestScreenCaptureAccess()
        }
    }

    @objc private func togglePanel(_ sender: NSStatusBarButton) {
        panelController?.toggle(relativeTo: statusItem?.button)
    }

    func openSettings() {
        if let window = settingsWindowController?.window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let view = SettingsView()
        let hostingController = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "AI Vision Assistant Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 480, height: 430))
        window.isReleasedWhenClosed = false
        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
