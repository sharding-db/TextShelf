#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h:h}"
cd "$PROJECT_DIR"
swift scripts/generate-icon.swift
swift build -c release --product TextShelf
BIN_DIR="$(swift build -c release --show-bin-path)"
STAGING_DIR="$(mktemp -d "$PROJECT_DIR/.build/package.XXXXXX")"
APP_DIR="$STAGING_DIR/TextShelf.app"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$BIN_DIR/TextShelf" "$APP_DIR/Contents/MacOS/TextShelf"
codesign --force --sign - "$APP_DIR"
codesign --verify --strict "$APP_DIR"
mkdir -p "$PROJECT_DIR/dist"
# Keep the previous executable intact if it is still running.
if [[ -e "$PROJECT_DIR/dist/TextShelf.app" ]]; then
    mv "$PROJECT_DIR/dist/TextShelf.app" "$STAGING_DIR/Previous-TextShelf.app"
fi
mv "$APP_DIR" "$PROJECT_DIR/dist/TextShelf.app"
APP_DIR="$PROJECT_DIR/dist/TextShelf.app"
printf '%s\n' "$APP_DIR"
