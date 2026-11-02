#!/bin/zsh
set -eu
cd "${0:A:h}"
make -C Vendor/m1ddc CC="clang -arch arm64 -mmacosx-version-min=13.0"
APP="$PWD/build/LG Sound.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Vendor/m1ddc/m1ddc "$APP/Contents/Resources/m1ddc"
cp Vendor/m1ddc/LICENSE "$APP/Contents/Resources/m1ddc-LICENSE"
cp Info.plist "$APP/Contents/Info.plist"
cp -R Resources/en.lproj Resources/ru.lproj "$APP/Contents/Resources/"
cp Assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
xcrun swiftc Sources/*.swift -o "$APP/Contents/MacOS/LG Sound" -O -swift-version 5 -target arm64-apple-macosx13.0 -framework Cocoa -framework CoreAudio -framework ServiceManagement
SIGNING_IDENTITY="${CODE_SIGN_IDENTITY:-}"
if [[ -z "$SIGNING_IDENTITY" && -f .signing-identity ]]; then SIGNING_IDENTITY="$(< .signing-identity)"; fi
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
SIGNING_FLAGS=(--force --sign "$SIGNING_IDENTITY")
if [[ "$SIGNING_IDENTITY" != "-" ]]; then SIGNING_FLAGS+=(--options runtime --timestamp); fi
codesign "${SIGNING_FLAGS[@]}" "$APP/Contents/Resources/m1ddc"
codesign "${SIGNING_FLAGS[@]}" "$APP"
echo "Готово: $APP"
