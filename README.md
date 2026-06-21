# Control Room

*English · [한국어](README.ko.md)*

A macOS menu-bar app that shows a floating bar with **a preview of the frontmost
window plus the app name for every desktop (Space) at a glance** — click to jump
straight to that window/desktop. See what's running on each desktop without
bouncing through Mission Control.

- Each desktop shows **one preview (its frontmost window) + the app name** ("None" if empty).
- Move the bar with the **left grip**; resize **Dock-style (aspect-preserving)** from the **edges or the bottom-right grip**. Position/size are saved automatically.

## How it works

macOS **only renders the currently active Space**, so the contents of other
desktops can't be captured through public APIs. Like Mission Control, Control
Room uses Apple's private **SkyLight (SLS)** framework — the same approach taken
by proven open-source tools such as yabai and AltTab.

- `SLSCopyManagedDisplaySpaces` — list every display's Spaces / the current Space
- `SLSCopyWindowsWithOptionsAndTags` — the window list per Space (we take the frontmost)
- `SLSHWCaptureWindowList` — capture a preview of that one front window (incl. windows on other Spaces)
- Accessibility (`AXRaise`) — on click, jump to that window (= switch to its Space)

> ⚠️ Because it relies on private APIs, Control Room may break when their
> signatures change across macOS releases (a version bump can require an update
> here). For the same reason it can't ship on the Mac App Store, so it's
> distributed directly as a DMG and as source. The window list refreshes once
> per second.

## Build

```bash
# Run during development
xcrun swift run -c release

# Build the .app bundle → dist/ControlRoom.app
./scripts/build-app.sh

# Build a distributable DMG → dist/ControlRoom.dmg
./scripts/make-dmg.sh
```

Requirements: macOS 13+, Swift 5.9+ from Xcode (or the Command Line Tools).

## Permissions (first launch)

Grant two permissions in `System Settings → Privacy & Security`:

1. **Screen Recording** — needed to capture the front-window previews. **Restart the app** after granting.
2. **Accessibility** — needed to focus (jump to) windows on other Spaces.

The app requests both on first launch. You can re-request them from the menu-bar
icon → "Re-request Screen Recording Permission" / "Re-request Accessibility
Permission".

> The UI is localized: it shows English by default and Korean when the system's
> preferred language is Korean. Menu labels below use the English wording.

## Usage

- On launch, the Control Room bar appears at the top of the screen.
- Toggle it with the menu-bar icon (▦) or the "Show/Hide Control Room" menu item.
- Each item = one desktop. A blue number badge = the current desktop.
- Click a card → jump to that desktop's frontmost window. Click an empty desktop ("None") → switch to it.
- Drag the **left dotted grip** to move; drag an **edge** or the **bottom-right diagonal grip** to resize Dock-style (aspect-preserving). Position/size are saved.
- Menu → "Reset Position & Size" resets to the default position/size.

## Distribution note (unsigned app)

Gatekeeper may block the app the first time someone opens a downloaded DMG.
Right-click → "Open", or clear the quarantine attribute in Terminal:

```bash
xattr -dr com.apple.quarantine /Applications/ControlRoom.app
```

## Limitations / roadmap

- Only the frontmost window of each desktop is previewed (other windows are omitted).
- Previews of inactive Spaces show their "last seen" frame (those Spaces aren't rendered); only the current Space updates live.
- Because the panel is nonactivating, the edge-resize **cursor** may not appear — visible grips are provided as the affordance instead.
- Global hotkey, better multi-monitor layout, and drag-window-to-another-Space are future work.

## License

[MIT](LICENSE) © jonghoonpark

## Support

If you find Control Room useful, you can support its development:

<a href="https://buymeacoffee.com/jonghoonpark"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee" /></a>
