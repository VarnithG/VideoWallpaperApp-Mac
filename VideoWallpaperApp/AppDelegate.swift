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
        print("App did finish launching")
        
        // Activate app immediately
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Create and show main window immediately
        createAndShowWindow()
        
        // Create status bar item
        setupStatusBar()
        
        // Request necessary permissions
        requestPermissions()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running in background when window is closed
        return false
    }
    
    private func createAndShowWindow() {
        print("Creating window...")
        
        let contentView = ContentView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Video Wallpaper"
        window.center()
        window.contentViewController = NSHostingController(rootView: contentView)
        
        // Set window level to ensure it's visible
        window.level = .floating
        
        // Store reference
        mainWindow = window
        
        // Show window immediately
        window.makeKeyAndOrderFront(nil)
        
        // Force app activation
        NSApp.activate(ignoringOtherApps: true)
        
        print("Window created and shown")
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
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            createAndShowWindow()
        }
    }
    
    // MARK: - Create App Icon
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
}

// MARK: - Status Bar View
struct StatusBarView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Video Wallpaper")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("Quick Controls")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Controls
            VStack(spacing: 0) {
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
        .frame(width: 280, height: 200)
    }
}