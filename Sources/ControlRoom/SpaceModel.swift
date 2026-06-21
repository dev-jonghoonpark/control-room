import AppKit

/// The frontmost window of a space — its app name plus a preview thumbnail.
struct WindowRef {
    let id: UInt32          // CGWindowID
    let pid: pid_t
    let owner: String       // app name
    let title: String       // window title (tooltip)
    var image: NSImage?     // preview of this front window
}

/// One space (desktop) on a display.
struct SpaceSnapshot: Identifiable {
    let id: Int             // ManagedSpaceID
    let index: Int          // 1-based label number
    let displayUUID: String
    let isCurrent: Bool
    let isFullscreen: Bool
    let frontWindow: WindowRef?   // nil = empty desktop

    var label: String {
        isFullscreen ? L.t("Full", "전체화면") : "\(index)"
    }
}
