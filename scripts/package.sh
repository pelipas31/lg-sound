#!/bin/zsh
set -eu
cd "${0:A:h:h}"
./build.sh
mkdir -p dist
APP_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)
ARCHIVE="LG-Sound-${APP_VERSION}-arm64.zip"
ditto -c -k --sequesterRsrc --keepParent 'build/LG Sound.app' "dist/$ARCHIVE"
cd dist
shasum -a 256 "$ARCHIVE" > SHA256SUMS.txt
echo "Package: dist/$ARCHIVE"
