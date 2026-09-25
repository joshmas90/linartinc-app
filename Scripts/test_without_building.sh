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
SUITE="${TEST_SUITE:-unit}"
RETRIES="${UI_TEST_RETRIES:-1}"

case "$SUITE" in
  unit)
    ONLY_TESTING=(-only-testing:LINARTTests)
    RETRIES=0
    ;;
  smoke)
    ONLY_TESTING=(
      -only-testing:LINARTUITests/PlanningFlowTests/testLargeTextPlanning
      -only-testing:LINARTUITests/PlanningFlowTests/testSkipEmptyPlanAndResume
    )
    ;;
  ui)
    ONLY_TESTING=(-only-testing:LINARTUITests)
    ;;
  all)
    ONLY_TESTING=()
    ;;
  *)
    echo "Unknown TEST_SUITE '$SUITE'. Expected unit, smoke, ui or all." >&2
    exit 2
    ;;
esac

run_attempt() {
  local attempt="$1"
  local result="build/${LINART_SIMULATOR_FAMILY}-${SUITE}-attempt${attempt}-TestResults.xcresult"
  local log="build/${LINART_SIMULATOR_FAMILY}-${SUITE}-attempt${attempt}-xcodebuild.log"
  rm -rf "$result"

  xcodebuild test-without-building \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$LINART_SIMULATOR_ID" \
    -destination-timeout 120 \
    -parallel-testing-enabled NO \
    -derivedDataPath build/DerivedData \
    -resultBundlePath "$result" \
    "${ONLY_TESTING[@]}" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
    2>&1 | tee "$log"
}

attempt=1
while true; do
  if run_attempt "$attempt"; then
    echo "LINART $SUITE tests passed on attempt $attempt."
    exit 0
  fi
  if (( attempt > RETRIES )); then
    echo "LINART $SUITE tests failed after $attempt attempt(s)." >&2
    exit 65
  fi
  echo "LINART $SUITE tests failed on attempt $attempt; resetting simulator and retrying once."
  xcrun simctl shutdown "$LINART_SIMULATOR_ID" >/dev/null 2>&1 || true
  xcrun simctl boot "$LINART_SIMULATOR_ID" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$LINART_SIMULATOR_ID" -b
  attempt=$((attempt + 1))
done
