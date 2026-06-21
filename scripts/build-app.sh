#!/bin/bash
# Build ControlRoom.app from the SwiftPM executable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP="$ROOT/dist/ControlRoom.app"
BIN_NAME="ControlRoom"

echo "▶ Building release binary…"
xcrun swift build -c release

BIN_PATH="$(xcrun swift build -c release --show-bin-path)/$BIN_NAME"

echo "▶ Assembling app bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH" "$APP/Contents/MacOS/$BIN_NAME"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

echo "▶ Ad-hoc code signing (stable TCC identity)…"
codesign --force --deep --sign - "$APP"

echo "✅ Built: $APP"
