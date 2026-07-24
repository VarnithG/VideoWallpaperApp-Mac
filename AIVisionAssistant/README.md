# AI Vision Assistant

AI Vision Assistant is a lightweight macOS menu bar utility. It captures the
main display with ScreenCaptureKit, sends the image and a configurable prompt
to OpenAI, Anthropic, or Google Gemini, and presents the answer in a compact
floating panel.

The app is menu-bar-only: `LSUIElement=true` and the accessory activation
policy prevent a Dock icon. The response panel uses
`NSWindow.SharingType.none`, so it is excluded from screen capture and
screen-sharing streams.

## Layout

- `AIVisionAssistant/`: AppKit bootstrap, coordinator, and global hotkey.
- `AIVisionAssistant/ScreenCapture/`: ScreenCaptureKit and macOS 13 fallback.
- `AIVisionAssistant/API/`: Provider definitions and Codable HTTP clients.
- `AIVisionAssistant/Settings/`: UserDefaults settings and Keychain storage.
- `AIVisionAssistant/Window/`: Control and response panels.
- `AIVisionAssistant/UI/`: SwiftUI views.
- `Info.plist`: `LSUIElement` and `NSScreenCaptureUsageDescription`.
- `AIVisionAssistant.entitlements`: minimal network-client entitlement.

## Build

On macOS 13 or newer, either open the directory as a Swift Package in Xcode,
or run:

```sh
cd AIVisionAssistant
./build.sh
./create_app_bundle.sh
open build/AIVisionAssistant.app
```

The scripts target `arm64-apple-macosx13.0`. The app is intentionally
non-sandboxed; sandboxing screen capture and Keychain access requires
additional entitlement and signing configuration.

## Permissions and setup

On first launch, macOS may request screen recording permission. If needed,
grant it under **System Settings > Privacy & Security > Screen Recording**,
then relaunch the app. The usage explanation is provided by
`NSScreenCaptureUsageDescription` in `Info.plist`.

Open **Settings…** from the menu bar panel, select a provider, enter its model
and API key, and customize the system prompt. API keys are stored per provider
in the macOS Keychain, not in UserDefaults. The default models are `gpt-4o`,
`claude-3-5-sonnet-20241022`, and `gemini-1.5-flash`; models can be changed as
providers update their APIs.

Press **Capture & Analyze** or the global **Command-Shift-S** shortcut to run
the pipeline. The panel handles provider HTTP errors and missing-key errors
without terminating the app.
