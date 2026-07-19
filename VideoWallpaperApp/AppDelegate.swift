import Cocoa
import SwiftUI
import ApplicationServices
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up the application
        setupApplication()
        
        // Create and show main window
        showMainWindow()
        
        // Create status bar item
        setupStatusBar()
        
        // Request necessary permissions
        requestPermissions()
    }
    
    private func setupApplication() {
        // Ensure the app is activated
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Set app icon
        if let icon = createAppIcon() {
            NSApplication.shared.applicationIconImage = icon
        }
    }
    
    private func createAppIcon() -> NSImage? {
        let size = NSSize(width: 512, height: 512)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create gradient background
        let gradient = NSGradient(colors: [
            NSColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 1.0),  // Bright blue
            NSColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)   // Purple
        ])
        
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        // Draw rounded rectangle for modern look
        let cornerRadius: CGFloat = 60
        let iconRect = NSRect(x: size.width * 0.2, y: size.height * 0.2, 
                             width: size.width * 0.6, height: size.height * 0.6)
        
        let roundedPath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.white.withAlphaComponent(0.2).setFill()
        roundedPath.fill()
        
        // Draw video play symbol
        let centerX = iconRect.midX
        let centerY = iconRect.midY
        let playSize: CGFloat = 60
        
        let playPath = NSBezierPath()
        playPath.move(to: NSPoint(x: centerX - playSize * 0.3, y: centerY - playSize))
        playPath.line(to: NSPoint(x: centerX - playSize * 0.3, y: centerY + playSize))
        playPath.line(to: NSPoint(x: centerX + playSize * 0.5, y: centerY))
        playPath.close()
        
        NSColor.white.setFill()
        playPath.fill()
        
        // Add inner glow
        let innerGlow = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.0),
            NSColor.white.withAlphaComponent(0.3),
            NSColor.white.withAlphaComponent(0.0)
        ])
        
        innerGlow?.draw(in: iconRect, angle: 0)
        
        image.unlockFocus()
        
        return image
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
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
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
    @objc func showMainWindow() {
        // Activate the app first
        NSApp.activate(ignoringOtherApps: true)
        
        if let existingWindow = mainWindow {
            existingWindow.makeKeyAndOrderFront(nil)
        } else {
            // Create new window
            let contentView = ContentView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("MainWindow")
            window.title = "Video Wallpaper"
            window.contentViewController = NSHostingController(rootView: contentView)
            
            // Store reference
            mainWindow = window
            
            // Make window visible and key
            window.level = .normal
            window.makeKeyAndOrderFront(nil)
            
            // Force window to front
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
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
                
                if wallpaperManager.currentWallpaper != nil {
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
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.showMainWindow()
                    }
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