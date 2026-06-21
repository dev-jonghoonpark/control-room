import SwiftUI

/// Observable model backing the overlay. Refreshes thumbnails on a background
/// queue so the WindowServer calls never block the UI.
final class SpaceStore: ObservableObject {
    @Published var spaces: [SpaceSnapshot] = []

    private let queue = DispatchQueue(label: "dev.controlroom.capture", qos: .userInitiated)
    private var refreshing = false

    func refresh() {
        if refreshing { return }
        refreshing = true
        let previous = spaces
        queue.async { [weak self] in
            let snap = SpaceManager.snapshot(previous: previous)
            DispatchQueue.main.async {
                self?.spaces = snap
                self?.refreshing = false
            }
        }
    }
}
