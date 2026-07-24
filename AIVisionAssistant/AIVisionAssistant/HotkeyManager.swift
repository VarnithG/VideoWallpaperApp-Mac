import Carbon.HIToolbox
import AppKit

final class HotkeyManager {
    private static weak var current: HotkeyManager?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    func register() {
        unregister()
        Self.current = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in
                DispatchQueue.main.async {
                    HotkeyManager.current?.callback()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &handlerRef
        )
        guard handlerStatus == noErr else { return }

        let identifier = EventHotKeyID(signature: OSType(0x41495641), id: 1)
        let modifiers = UInt32(cmdKey | shiftKey)
        let registrationStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_S),
            modifiers,
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if registrationStatus != noErr {
            unregister()
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
        if Self.current === self {
            Self.current = nil
        }
    }

    deinit {
        unregister()
    }
}
