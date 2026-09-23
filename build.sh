#!/bin/bash
# 실행 파일과 리소스를 .app 번들로 조립한다.
set -euo pipefail

cd "$(dirname "$0")"

NAME="ClaudeUsageMonitor"
BUNDLE="build/${NAME}.app"

swift build -c release --product UsageApp

rm -rf "$BUNDLE"
mkdir -p "${BUNDLE}/Contents/MacOS" "${BUNDLE}/Contents/Resources"

cp Resources/Info.plist "${BUNDLE}/Contents/Info.plist"
cp "$(swift build -c release --show-bin-path)/UsageApp" "${BUNDLE}/Contents/MacOS/${NAME}"

# locales는 저장소 루트에 두고 두 구현이 공유한다. 번들에는 복사본이 들어간다.
cp -R locales "${BUNDLE}/Contents/Resources/locales"

echo "빌드 완료: ${BUNDLE}"
echo "설치하려면: cp -R \"${BUNDLE}\" /Applications/"
