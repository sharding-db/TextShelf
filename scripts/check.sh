#!/bin/zsh
set -euo pipefail
PROJECT_DIR="${0:A:h:h}"
cd "$PROJECT_DIR"
swift build --product ClipboardChecks --enable-code-coverage
DEBUG_DIR="$(swift build --show-bin-path)"
LLVM_PROFILE_FILE="$PROJECT_DIR/.build/clipboard-checks.profraw" "$DEBUG_DIR/ClipboardChecks"
./scripts/build.sh
RELEASE_DIR="$(swift build -c release --show-bin-path)"
swiftc -I "$RELEASE_DIR/Modules" \
    "$RELEASE_DIR/ClipboardCore.build"/*.o \
    "$RELEASE_DIR/ClipboardMac.build"/*.o \
    Sources/TextShelf/ClipboardModel.swift Sources/TextShelf/HistoryView.swift \
    scripts/check-layout.swift -o .build/LayoutChecks
.build/LayoutChecks
xcrun llvm-profdata merge -sparse .build/clipboard-checks.profraw -o .build/clipboard-checks.profdata
xcrun llvm-cov report "$DEBUG_DIR/ClipboardChecks" -instr-profile=.build/clipboard-checks.profdata \
    Sources/ClipboardCore/ClipboardHistory.swift Sources/ClipboardMac/AppKitTextPasteboard.swift
codesign --verify --strict dist/TextShelf.app
