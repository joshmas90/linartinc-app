#!/bin/bash
set -euo pipefail
python3 Scripts/verify_package.py --root .
mkdir -p build
xcodebuild -version | tee build/xcode-version.log
xcrun simctl list devices available --json > build/simulators.json
FAMILY="${SIMULATOR_FAMILY:-iPhone}"
SIMULATOR_ID=$(python3 - "$FAMILY" <<'PY'
import json, re, sys
devices = json.load(open('build/simulators.json'))['devices']
candidates = []
for runtime, values in devices.items():
    match = re.fullmatch(r'com\.apple\.CoreSimulator\.SimRuntime\.iOS-(\d+(?:-\d+)*)', runtime)
    if not match: continue
    version = tuple(map(int, match[1].split('-')))
    for device in values:
        if version >= (17,) and device.get('isAvailable') and device['name'].startswith(sys.argv[1]):
            candidates.append((version, device['name'], device['udid']))
if not candidates: raise SystemExit('No compatible simulator found')
print(max(candidates)[2])
PY
)
xcodebuild test -project LINART.xcodeproj -scheme LINART -configuration Debug \
  -sdk iphonesimulator -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -destination-timeout 120 -parallel-testing-enabled NO \
  -derivedDataPath build/DerivedData -resultBundlePath "build/$FAMILY-TestResults.xcresult" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  2>&1 | tee "build/$FAMILY-xcodebuild.log"
