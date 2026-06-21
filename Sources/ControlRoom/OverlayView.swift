import SwiftUI

/// Reports the natural (scale-1) size of the bar content up to the controller,
/// which uses it to lock the window's aspect ratio.
private struct BaseSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let n = nextValue()
        if n.width > value.width { value = n }
    }
}

/// Scales the whole bar uniformly to fill the window — Dock-style zoom on resize.
struct OverlayView: View {
    @ObservedObject var store: SpaceStore
    var leadingInset: CGFloat = 0
    var onBaseSize: (CGSize) -> Void

    @State private var baseSize: CGSize = CGSize(width: 320, height: 44)

    var body: some View {
        GeometryReader { geo in
            let scale = baseSize.height > 1 ? geo.size.height / baseSize.height : 1
            BarContent(store: store)
                .padding(.leading, leadingInset)   // room for the drag grip
                .fixedSize()                       // natural, unconstrained size
                .background(GeometryReader { g in
                    Color.clear.preference(key: BaseSizeKey.self, value: g.size)
                })
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onPreferenceChange(BaseSizeKey.self) { size in
            guard size.width > 1, size.height > 1 else { return }
            baseSize = size
            onBaseSize(size)
        }
    }
}

private struct BarContent: View {
    @ObservedObject var store: SpaceStore

    var body: some View {
        HStack(spacing: 8) {
            ForEach(store.spaces) { space in
                SpacePill(space: space)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

private struct SpacePill: View {
    let space: SpaceSnapshot

    // Every card is exactly this wide so long window names never bloat a card.
    private let cardWidth: CGFloat = 124
    private let previewHeight: CGFloat = 74

    private var appName: String { space.frontWindow?.owner ?? L.t("None", "없음") }
    private var isEmpty: Bool { space.frontWindow == nil }

    var body: some View {
        Button(action: jump) {
            VStack(spacing: 4) {
                preview
                HStack(spacing: 5) {
                    Text(space.label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(space.isCurrent ? Color.white : .secondary)
                        .frame(minWidth: 14)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(space.isCurrent
                                ? Color.accentColor
                                : Color.secondary.opacity(0.25)))
                    Text(appName)
                        .font(.system(size: 11, weight: space.isCurrent ? .semibold : .regular))
                        .foregroundStyle(isEmpty ? .tertiary : .primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                .frame(width: cardWidth)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(space.isCurrent ? Color.accentColor.opacity(0.12) : Color.black.opacity(0.05)))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(space.isCurrent ? Color.accentColor.opacity(0.6) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    @ViewBuilder private var preview: some View {
        Group {
            if let img = space.frontWindow?.image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.secondary.opacity(0.12)
                    Text(isEmpty ? "없음" : appName)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, 6)
                }
            }
        }
        .frame(width: cardWidth, height: previewHeight)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.black.opacity(0.15), lineWidth: 0.5))
    }

    private var tooltip: String {
        guard let w = space.frontWindow else { return "\(space.label) — " + L.t("Empty", "비어 있음") }
        return w.title.isEmpty ? w.owner : "\(w.owner) — \(w.title)"
    }

    private func jump() {
        WindowActions.jump(to: space)
    }
}
