#!/bin/zsh
set -eu
cd "${0:A:h:h}"
mkdir -p build
xcrun swiftc -swift-version 5 Sources/MediaKeyRecovery.swift Tests/main.swift -o build/test-media-recovery
build/test-media-recovery
