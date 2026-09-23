#!/bin/bash
# Build the .app bundle. Pass --install to copy it into /Applications.
set -euo pipefail

cd "$(dirname "$0")"

NAME="ClaudeUsageMonitor"
BUNDLE="build/${NAME}.app"

swift build -c release --product UsageApp

rm -rf "$BUNDLE"
mkdir -p "${BUNDLE}/Contents/MacOS" "${BUNDLE}/Contents/Resources"

cp Resources/Info.plist "${BUNDLE}/Contents/Info.plist"
cp "$(swift build -c release --show-bin-path)/UsageApp" "${BUNDLE}/Contents/MacOS/${NAME}"
cp -R locales "${BUNDLE}/Contents/Resources/locales"

echo "Built ${BUNDLE}"

if [ "${1:-}" = "--install" ]; then
  # Replacing a running app leaves a stale process behind.
  pkill -f "${NAME}" 2>/dev/null || true
  rm -rf "/Applications/${NAME}.app"
  cp -R "${BUNDLE}" /Applications/
  open "/Applications/${NAME}.app"
  echo "Installed to /Applications and launched"
else
  echo "Run ./build.sh --install to install it"
fi
