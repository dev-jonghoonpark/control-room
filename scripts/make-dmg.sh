#!/bin/bash
# Package ControlRoom.app into a distributable DMG.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP="$ROOT/dist/ControlRoom.app"
[ -d "$APP" ] || "$ROOT/scripts/build-app.sh"

STAGE="$ROOT/dist/dmg-stage"
DMG="$ROOT/dist/ControlRoom.dmg"

echo "▶ Staging…"
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "▶ Creating DMG…"
hdiutil create -volname "Control Room" \
    -srcfolder "$STAGE" \
    -ov -format UDZO \
    "$DMG"

rm -rf "$STAGE"
echo "✅ DMG: $DMG"
