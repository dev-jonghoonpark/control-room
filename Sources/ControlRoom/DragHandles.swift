import AppKit

/// A single transparent view laid over the whole bar. It owns the cursor and the
/// move/resize drags. A borderless, nonactivating panel doesn't get native
/// resize cursors, and stacking many thin tracking views on top of an
/// NSHostingView proved unreliable, so we centralize everything here:
///   • cursor is decided per mouse position (edge → resize, grip → hand)
///   • interior points fall through (hitTest → nil) so SwiftUI cards stay clickable
final class BarOverlayView: NSView {
    var onFrameChanged: (() -> Void)?

    let edge: CGFloat = 10        // resize hot-zone thickness
    let gripWidth: CGFloat = 18   // left move-grip width

    enum Zone { case left, right, top, bottom, grip, interior }

    init(onFrameChanged: @escaping () -> Void) {
        self.onFrameChanged = onFrameChanged
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    private func zone(at p: NSPoint) -> Zone {
        let b = bounds
        if p.x <= edge { return .left }
        if p.x >= b.maxX - edge { return .right }
        if p.y >= b.maxY - edge { return .top }
        if p.y <= edge { return .bottom }
        if p.x <= edge + gripWidth { return .grip }
        return .interior
    }

    private func cursor(for z: Zone) -> NSCursor {
        switch z {
        case .left, .right:  return .resizeLeftRight
        case .top, .bottom:  return .resizeUpDown
        case .grip:          return .openHand
        case .interior:      return .arrow
        }
    }

    // Pass interior clicks through to the SwiftUI cards underneath.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let sv = superview else { return nil }
        let p = convert(point, from: sv)
        guard bounds.contains(p) else { return nil }
        return zone(at: p) == .interior ? nil : self
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    // MARK: Cursor tracking

    private var trackingAreaRef: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = trackingAreaRef { removeTrackingArea(t) }
        let t = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .cursorUpdate],
            owner: self, userInfo: nil)
        addTrackingArea(t)
        trackingAreaRef = t
    }

    private func updateCursor(_ event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        cursor(for: zone(at: p)).set()
    }

    override func mouseMoved(with event: NSEvent) { updateCursor(event) }
    override func mouseEntered(with event: NSEvent) { updateCursor(event) }
    override func cursorUpdate(with event: NSEvent) { updateCursor(event) }
    override func mouseExited(with event: NSEvent) { NSCursor.arrow.set() }

    // MARK: Drag (move + resize)

    private var dragZone: Zone = .interior
    private var initialFrame: NSRect = .zero
    private var initialMouse: NSPoint = .zero

    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }
        dragZone = zone(at: convert(event.locationInWindow, from: nil))
        if dragZone == .grip {
            NSCursor.closedHand.set()
            window.performDrag(with: event)   // runs the whole move loop
            onFrameChanged?()
            return
        }
        initialFrame = window.frame
        initialMouse = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = window, dragZone != .interior, dragZone != .grip else { return }
        cursor(for: dragZone).set()
        let now = NSEvent.mouseLocation
        let dx = now.x - initialMouse.x
        let dy = now.y - initialMouse.y
        let aspect = initialFrame.width / max(initialFrame.height, 1)
        let minH = max(window.minSize.height, 1)
        let minW = minH * aspect

        var f = initialFrame
        switch dragZone {
        case .right:
            let w = max(minW, initialFrame.width + dx)
            f.size = NSSize(width: w, height: w / aspect)
        case .left:
            let w = max(minW, initialFrame.width - dx)
            f.size = NSSize(width: w, height: w / aspect)
            f.origin.x = initialFrame.maxX - w
        case .top:
            let h = max(minH, initialFrame.height + dy)
            f.size = NSSize(width: h * aspect, height: h)
            f.origin.y = initialFrame.minY
        case .bottom:
            let h = max(minH, initialFrame.height - dy)
            f.size = NSSize(width: h * aspect, height: h)
            f.origin.y = initialFrame.maxY - h
        case .grip, .interior:
            break
        }
        window.setFrame(f, display: true)
    }

    override func mouseUp(with event: NSEvent) {
        if dragZone != .interior, dragZone != .grip { onFrameChanged?() }
        dragZone = .interior
    }

    // MARK: Affordances (grip dots + bottom-right resize lines)

    override func draw(_ dirtyRect: NSRect) {
        let b = bounds

        // Left grip: 2×3 dots.
        let dot: CGFloat = 2.5, sx: CGFloat = 5, sy: CGFloat = 6
        let cols = 2, rows = 3
        let gx = edge + gripWidth / 2 - CGFloat(cols - 1) * sx / 2
        let gy = b.midY - CGFloat(rows - 1) * sy / 2
        NSColor.secondaryLabelColor.withAlphaComponent(0.55).setFill()
        for r in 0..<rows {
            for c in 0..<cols {
                let rect = NSRect(x: gx + CGFloat(c) * sx - dot / 2,
                                  y: gy + CGFloat(r) * sy - dot / 2,
                                  width: dot, height: dot)
                NSBezierPath(ovalIn: rect).fill()
            }
        }

        // Bottom-right resize grip: 3 diagonal lines.
        let p = NSBezierPath()
        p.lineWidth = 1
        let m: CGFloat = 4
        for i in 1...3 {
            let off = CGFloat(i) * 4
            p.move(to: NSPoint(x: b.maxX - m, y: b.minY + m + off))
            p.line(to: NSPoint(x: b.maxX - m - off, y: b.minY + m))
        }
        NSColor.secondaryLabelColor.withAlphaComponent(0.5).setStroke()
        p.stroke()
    }
}

/// Hosts the SwiftUI bar with the overlay on top.
final class BarContainerView: NSView {
    private let content: NSView
    private let overlay: BarOverlayView

    init(content: NSView, onFrameChanged: @escaping () -> Void) {
        self.content = content
        self.overlay = BarOverlayView(onFrameChanged: onFrameChanged)
        super.init(frame: .zero)
        autoresizesSubviews = false
        addSubview(content)
        addSubview(overlay)   // on top
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        content.frame = bounds
        overlay.frame = bounds
        overlay.needsDisplay = true
    }
    override func layout() {
        super.layout()
        content.frame = bounds
        overlay.frame = bounds
    }
}
