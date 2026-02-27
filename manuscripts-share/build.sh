#!/usr/bin/env bash
# Build manuscripts-share for macOS.
#
# Usage:  ./build.sh [version]
# Output: dist/manuscripts-share-mac-v{version}.dmg

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERSION="${1:-1.0}"
DMG="manuscripts-share-mac-v${VERSION}.dmg"

echo "Building manuscripts-share v${VERSION} for macOS..."

# Use a build venv to avoid Homebrew's externally-managed-environment restriction
python3 -m venv "${SCRIPT_DIR}/.build-venv"
source "${SCRIPT_DIR}/.build-venv/bin/activate"
pip install --quiet pyinstaller aiohttp zeroconf pystray Pillow pyobjc

python3 make_icons.py

pyinstaller --onedir --windowed \
    --name manuscripts-share \
    --icon icon.icns \
    --collect-all zeroconf \
    --collect-all aiohttp \
    --collect-all pystray \
    --hidden-import pystray._darwin \
    --hidden-import tkinter \
    --add-data "JetBrainsMono-Regular.ttf:." \
    --add-data "JetBrainsMono-Light.ttf:." \
    share.py

# Build DMG with an Applications symlink for drag-and-drop install
rm -rf dist/dmg-staging
mkdir dist/dmg-staging
cp -r "dist/manuscripts-share.app" "dist/dmg-staging/"
ln -s /Applications "dist/dmg-staging/Applications"

hdiutil create \
    -volname "manuscripts-share" \
    -srcfolder "dist/dmg-staging" \
    -ov \
    -format UDZO \
    "dist/${DMG}"

rm -rf dist/dmg-staging

echo ""
echo "Done: dist/${DMG}"
echo ""
echo "Distribute this DMG. Users open it, drag manuscripts-share to Applications."
echo "Note: on first run macOS may block the app. Right-click → Open to bypass."
