import SwiftUI

/// Owns the floating bar and the refresh timer. The bar zooms uniformly on
/// resize (Dock-style): the window aspect ratio is locked to the content's
/// natural ratio and the SwiftUI content is scaled to fill.
final class OverlayController {
    private let store = SpaceStore()
    private var panel: NSPanel?
    private var timer: Timer?
    private(set) var isVisible = false

    private let defaultHeight: CGFloat = 124
    private let autosaveName = "ControlRoomPanel"
    private var baseSize: CGSize = .zero

    func toggle() {
        isVisible ? hide() : show()
    }

    func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        clampIntoVisibleArea(panel)
        store.refresh()
        panel.orderFrontRegardless()
        startTimer()
        isVisible = true
    }

    func hide() {
        stopTimer()
        panel?.orderOut(nil)
        isVisible = false
    }

    /// Reset the bar back to its default position (top-center) and size.
    func resetFrame() {
        let panel = panel ?? makePanel()
        self.panel = panel

        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let width = (baseSize.height > 1)
            ? (defaultHeight * baseSize.width / baseSize.height).rounded()
            : 420
        let frame = NSRect(x: vf.midX - width / 2, y: vf.maxY - defaultHeight,
                           width: width, height: defaultHeight)
        panel.setFrame(frame, display: true)
        panel.saveFrame(usingName: autosaveName)

        if !isVisible { show() } else { panel.orderFrontRegardless() }
    }

    // MARK: - Panel construction

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: defaultHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)

        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating                    // above app windows, under the menu bar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isMovable = true
        panel.isMovableByWindowBackground = false  // move via the grip handle only
        panel.acceptsMouseMovedEvents = true        // needed for live cursor updates
        panel.minSize = NSSize(width: 160, height: 70)

        let view = OverlayView(store: store, leadingInset: 30) { [weak self] base in
            self?.applyBaseSize(base)
        }
        let host = NSHostingView(rootView: view)
        host.autoresizingMask = [.width, .height]

        let container = BarContainerView(content: host) { [weak self] in
            guard let self, let p = self.panel else { return }
            p.saveFrame(usingName: self.autosaveName)
        }
        container.wantsLayer = true
        container.layer?.cornerRadius = 12
        container.layer?.cornerCurve = .continuous
        container.layer?.masksToBounds = true
        panel.contentView = container

        if !panel.setFrameUsingName(autosaveName) {
            positionAtTop(panel)
        }
        panel.setFrameAutosaveName(autosaveName)
        clampIntoVisibleArea(panel)
        return panel
    }

    /// Keep the bar fully inside the screen's visible area so it never tucks
    /// under the menu bar or off-screen.
    private func clampIntoVisibleArea(_ panel: NSPanel) {
        guard let screen = panel.screen ?? NSScreen.main else { return }
        let vf = screen.visibleFrame
        var f = panel.frame
        if f.maxY > vf.maxY { f.origin.y = vf.maxY - f.height }
        if f.minY < vf.minY { f.origin.y = vf.minY }
        if f.maxX > vf.maxX { f.origin.x = vf.maxX - f.width }
        if f.minX < vf.minX { f.origin.x = vf.minX }
        if f != panel.frame { panel.setFrame(f, display: true) }
    }

    /// Lock the window's aspect ratio to the content's natural ratio so dragging
    /// any edge scales the bar uniformly. When content count changes the ratio
    /// shifts, so we refit the width to the current height.
    private func applyBaseSize(_ base: CGSize) {
        guard let panel, base.width > 1, base.height > 1 else { return }
        if abs(base.width - baseSize.width) < 0.5, abs(base.height - baseSize.height) < 0.5 {
            return
        }
        baseSize = base
        panel.contentAspectRatio = base

        var frame = panel.frame
        let targetWidth = (frame.height * base.width / base.height).rounded()
        if abs(targetWidth - frame.width) > 0.5 {
            frame.size.width = targetWidth
            panel.setFrame(frame, display: true)
        }
    }

    private func positionAtTop(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let frame = NSRect(x: vf.midX - 210, y: vf.maxY - defaultHeight,
                           width: 420, height: defaultHeight)
        panel.setFrame(frame, display: true)
    }

    // MARK: - Refresh loop

    private func startTimer() {
        stopTimer()
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.store.refresh()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
