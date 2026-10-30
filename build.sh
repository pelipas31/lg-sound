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
xcrun swiftc Sources/main.swift -o "$APP/Contents/MacOS/LG Sound" -O -swift-version 5 -target arm64-apple-macosx13.0 -framework Cocoa -framework CoreAudio -framework ServiceManagement
codesign --force --sign - "$APP/Contents/Resources/m1ddc"
codesign --force --sign - "$APP"
echo "Готово: $APP"
