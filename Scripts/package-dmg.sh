#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.build/SnapGlass.app"
DIST_DIR="$ROOT_DIR/.build/dist"
STAGING_DIR="$ROOT_DIR/.build/dmg-staging"
APP_VERSION="${SNAPGLASS_VERSION:-0.1.0}"
DMG_NAME="${SNAPGLASS_DMG_NAME:-SnapGlass-${APP_VERSION}.dmg}"
DMG_PATH="$DIST_DIR/$DMG_NAME"

"$ROOT_DIR/Scripts/package-app.sh"

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR" "$DIST_DIR"

cp -R "$APP_DIR" "$STAGING_DIR/SnapGlass.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "SnapGlass" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Packaged $DMG_PATH"
