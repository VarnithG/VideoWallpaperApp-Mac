import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        setupStatusBar()
        
        // Request necessary permissions
        requestPermissions()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in background when window is closed
        return false
    }
    
    // MARK: - Setup Status Bar
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "video.fill", accessibilityDescription: "Video Wallpaper")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    // MARK: - Status Bar Button Clicked
    @objc private func statusBarButtonClicked() {
        if let popover = popover {
            if popover.isShown {
                popover.close()
            } else {
                showPopover()
            }
        } else {
            showPopover()
        }
    }
    
    // MARK: - Show Popover
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: StatusBarView())
        
        self.popover = popover
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
    
    // MARK: - Request Permissions
    private func requestPermissions() {
        // Request accessibility permissions for desktop wallpaper
        let options = [kAXTrustedCheckOptionPrompt.takeValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            // Show alert if accessibility is not enabled
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Video Wallpaper needs accessibility permission to display videos on your desktop. Please grant this permission in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
    
    // MARK: - Show Main Window
    func showMainWindow() {
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create new window
            let contentView = ContentView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("MainWindow")
            window.title = "Video Wallpaper"
            window.contentViewController = NSHostingController(rootView: contentView)
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Status Bar View
struct StatusBarView: View {
    @StateObject private var wallpaperManager = WallpaperManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Video Wallpaper")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                if let currentWallpaper = wallpaperManager.currentWallpaper {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            .padding()
            
            Divider()
            
            // Current Wallpaper
            if let currentWallpaper = wallpaperManager.currentWallpaper {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Wallpaper")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(currentWallpaper.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
            }
            
            // Controls
            VStack(spacing: 0) {
                Button(action: {
                    wallpaperManager.pauseDesktopWallpaper()
                }) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(action: {
                    wallpaperManager.resumeDesktopWallpaper()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Resume")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(action: {
                    wallpaperManager.stopDesktopWallpaper()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(action: {
                    dismiss()
                    NSApp.delegate?.perform(#selector(AppDelegate.showMainWindow))
                }) {
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                        Text("Open App")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 280, height: 400)
    }
}