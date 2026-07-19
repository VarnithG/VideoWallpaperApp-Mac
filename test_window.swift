import Cocoa

// Minimal window test
class WindowTest {
    static func showTestWindow() {
        print("Creating test window...")
        
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Test Window"
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.backgroundColor = NSColor.blue.cgColor
        
        print("Making window key and ordering front...")
        window.makeKeyAndOrderFront(nil)
        
        print("Activating app...")
        NSApp.activate(ignoringOtherApps: true)
        
        print("Window should be visible now")
    }
}

// Run test
WindowTest.showTestWindow()