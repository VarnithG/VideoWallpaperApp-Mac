import Cocoa
import SwiftUI

class MainController {
    static func run() {
        let app = NSApplication.shared
        
        // Create a simple menu
        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = app
        menu.addItem(quitItem)
        
        app.mainMenu = menu
        
        // Activate and set policy
        app.setActivationPolicy(.regular)
        
        // Create and show window
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
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        
        // Run the app
        app.activate(ignoringOtherApps: true)
        app.run()
    }
}

MainController.run()