#!/usr/bin/env bash
set -euo pipefail

test -f build/simulator.env || {
  echo "Missing build/simulator.env. Run Scripts/ci_preflight.sh first." >&2
  exit 2
}
# shellcheck disable=SC1091
source build/simulator.env

PROJECT="${XCODE_PROJECT:-LINART.xcodeproj}"
SCHEME="${XCODE_SCHEME:-LINART}"
LOG="build/${LINART_SIMULATOR_FAMILY}-build-for-testing.log"

xcodebuild build-for-testing \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$LINART_SIMULATOR_ID" \
  -destination-timeout 120 \
  -parallel-testing-enabled NO \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  2>&1 | tee "$LOG"
