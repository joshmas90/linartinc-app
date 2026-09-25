#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
python3 Scripts/verify_package.py --root .

if [[ "${RUN_BACKEND_TESTS:-1}" == "1" ]]; then
  node --test Backend/*.test.mjs | tee build/backend-tests.log
fi

xcodebuild -version | tee build/xcode-version.log
xcrun simctl list devices available --json > build/simulators.json

FAMILY="${SIMULATOR_FAMILY:-iPhone}"
RUNTIME_MAJOR="${SIMULATOR_RUNTIME_MAJOR:-26}"
if [[ -n "${SIMULATOR_NAME:-}" ]]; then
  PREFERRED_ARGS=(--preferred-name "$SIMULATOR_NAME")
else
  PREFERRED_ARGS=()
fi

python3 Scripts/select_simulator.py \
  --devices-json build/simulators.json \
  --family "$FAMILY" \
  --runtime-major "$RUNTIME_MAJOR" \
  "${PREFERRED_ARGS[@]}" \
  --output build/simulator.env

cat build/simulator.env
