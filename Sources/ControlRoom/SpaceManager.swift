import AppKit
import CGSPrivate

/// Enumerates spaces via the private SkyLight API, finds the frontmost window of
/// each space, and captures a preview thumbnail for *that one window only*.
enum SpaceManager {

    private static let captureOptions: UInt32 =
        UInt32(CRCaptureBestResolution.rawValue) |
        UInt32(CRCaptureIgnoreGlobalClipShape.rawValue)

    /// `previous` carries the last good thumbnail so cards don't flicker to blank
    /// when a one-off capture fails.
    static func snapshot(previous: [SpaceSnapshot]) -> [SpaceSnapshot] {
        let cid = SLSMainConnectionID()

        guard let displays = SLSCopyManagedDisplaySpaces(cid) as? [[String: Any]] else {
            return []
        }

        let metaById = collectWindowMeta()
        let ownPID = ProcessInfo.processInfo.processIdentifier

        var lastImage: [UInt32: NSImage] = [:]
        for space in previous {
            if let w = space.frontWindow, let img = w.image { lastImage[w.id] = img }
        }

        var result: [SpaceSnapshot] = []
        var desktopIndex = 0

        for display in displays {
            let displayUUID = display["Display Identifier"] as? String ?? "Main"
            let currentSpaceID = (display["Current Space"] as? [String: Any])?["ManagedSpaceID"] as? Int
            let spaces = display["Spaces"] as? [[String: Any]] ?? []

            for space in spaces {
                guard let sid = space["ManagedSpaceID"] as? Int else { continue }
                let type = space["type"] as? Int ?? 0
                let isFullscreen = (type == 4)
                if !isFullscreen { desktopIndex += 1 }

                // SLSCopyWindowsWithOptionsAndTags returns windows front-to-back,
                // so the first one that passes our filters is the frontmost.
                let windowIDs = windowIDsOnSpace(cid: cid, spaceID: sid)
                var front: WindowRef?
                for wid in windowIDs {
                    guard let meta = metaById[wid] else { continue }
                    if meta.pid == ownPID { continue }
                    if meta.layer != 0 { continue }
                    if meta.width < 40 || meta.height < 40 { continue }
                    let image = captureWindow(cid: cid, windowID: wid) ?? lastImage[wid]
                    front = WindowRef(id: wid, pid: meta.pid,
                                      owner: meta.owner, title: meta.title, image: image)
                    break
                }

                result.append(SpaceSnapshot(
                    id: sid,
                    index: isFullscreen ? 0 : desktopIndex,
                    displayUUID: displayUUID,
                    isCurrent: sid == currentSpaceID,
                    isFullscreen: isFullscreen,
                    frontWindow: front))
            }
        }
        return result
    }

    // MARK: - Private helpers

    private struct WindowMeta {
        let pid: pid_t
        let owner: String
        let title: String
        let layer: Int
        let width: CGFloat
        let height: CGFloat
    }

    private static func collectWindowMeta() -> [UInt32: WindowMeta] {
        let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
        guard let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return [:]
        }
        var map: [UInt32: WindowMeta] = [:]
        for info in list {
            guard let num = info[kCGWindowNumber as String] as? UInt32 else { continue }
            let pid = info[kCGWindowOwnerPID as String] as? pid_t ?? 0
            let owner = info[kCGWindowOwnerName as String] as? String ?? ""
            let title = info[kCGWindowName as String] as? String ?? ""
            let layer = info[kCGWindowLayer as String] as? Int ?? 0
            var w: CGFloat = 0, h: CGFloat = 0
            if let b = info[kCGWindowBounds as String] as? [String: CGFloat] {
                w = b["Width"] ?? 0
                h = b["Height"] ?? 0
            }
            map[num] = WindowMeta(pid: pid, owner: owner, title: title,
                                  layer: layer, width: w, height: h)
        }
        return map
    }

    private static func windowIDsOnSpace(cid: CGSConnectionID, spaceID: Int) -> [UInt32] {
        var setTags: UInt64 = 0
        var clearTags: UInt64 = 0
        let spaces = [spaceID] as CFArray
        guard let raw = SLSCopyWindowsWithOptionsAndTags(
            cid, 0, spaces, 0x2, &setTags, &clearTags) as? [NSNumber] else {
            return []
        }
        return raw.map { $0.uint32Value }
    }

    private static func captureWindow(cid: CGSConnectionID, windowID: UInt32) -> NSImage? {
        var wid = windowID
        guard let images = SLSHWCaptureWindowList(cid, &wid, 1, captureOptions) as? [CGImage],
              let cg = images.first else {
            return nil
        }
        return NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    }
}
