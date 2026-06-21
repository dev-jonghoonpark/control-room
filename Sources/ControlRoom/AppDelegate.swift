import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let overlay = OverlayController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        requestPermissions()
        setupStatusItem()
        overlay.show()   // open the control room immediately on launch
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "rectangle.3.group",
                                   accessibilityDescription: "Control Room")
            button.action = #selector(toggleOverlay)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L.t("Show/Hide Control Room", "컨트롤룸 표시/숨기기"),
                                action: #selector(toggleOverlay), keyEquivalent: "k"))
        menu.addItem(NSMenuItem(title: L.t("Reset Position & Size", "위치/사이즈 초기화"),
                                action: #selector(resetFrame), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L.t("Re-request Screen Recording Permission", "화면 기록 권한 재요청"),
                                action: #selector(requestScreenRecording), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L.t("Re-request Accessibility Permission", "손쉬운 사용 권한 재요청"),
                                action: #selector(requestPermissionsMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: L.t("Quit", "종료"),
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    @objc private func toggleOverlay() {
        overlay.toggle()
    }

    @objc private func resetFrame() {
        overlay.resetFrame()
    }

    @objc private func requestPermissionsMenu() {
        requestAccessibility()
    }

    /// Screen Recording → needed to capture window thumbnails.
    /// Accessibility   → needed to focus windows on other spaces.
    private func requestPermissions() {
        CGRequestScreenCaptureAccess()
        requestAccessibility(prompt: false)
    }

    private func requestAccessibility(prompt: Bool = true) {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    /// macOS only shows the Screen Recording prompt once; if it was already
    /// denied, re-requesting is a no-op, so we also open the settings pane.
    @objc private func requestScreenRecording() {
        let granted = CGRequestScreenCaptureAccess()
        if !granted {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
