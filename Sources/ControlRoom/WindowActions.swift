import AppKit
import CGSPrivate

/// Jumping to a space / focusing a window across spaces.
enum WindowActions {

    /// Move to the given space. The space switch itself goes through SkyLight
    /// (needs no Accessibility permission), guaranteeing the desktop changes;
    /// then we also raise the front window so keyboard focus lands there.
    static func jump(to space: SpaceSnapshot) {
        switchTo(spaceID: space.id, displayUUID: space.displayUUID)
        if let w = space.frontWindow {
            focus(windowID: w.id, pid: w.pid)
        }
    }

    /// Switch a display to a space directly. No animation, but reliable and
    /// permission-free.
    static func switchTo(spaceID: Int, displayUUID: String) {
        let cid = SLSMainConnectionID()
        SLSManagedDisplaySetCurrentSpace(cid, displayUUID as CFString, CGSSpaceID(spaceID))
    }

    /// Raise a specific window via Accessibility so it becomes the focused window
    /// on its space. Requires Accessibility permission.
    static func focus(windowID: UInt32, pid: pid_t) {
        NSRunningApplication(processIdentifier: pid)?
            .activate(options: [.activateIgnoringOtherApps])

        let axApp = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &value) == .success,
           let windows = value as? [AXUIElement] {
            for w in windows {
                var wid: UInt32 = 0
                if _AXUIElementGetWindow(w, &wid) == .success, wid == windowID {
                    AXUIElementPerformAction(w, kAXRaiseAction as CFString)
                    AXUIElementSetAttributeValue(w, kAXMainAttribute as CFString, kCFBooleanTrue)
                    return
                }
            }
        }
    }
}
