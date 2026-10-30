#!/bin/zsh
set -eu
cd "${0:A:h:h}"
./build.sh
mkdir -p dist
ditto -c -k --sequesterRsrc --keepParent 'build/LG Sound.app' dist/LG-Sound-1.0.0-arm64.zip
cd dist
shasum -a 256 LG-Sound-1.0.0-arm64.zip > SHA256SUMS.txt
echo "Package: dist/LG-Sound-1.0.0-arm64.zip"
