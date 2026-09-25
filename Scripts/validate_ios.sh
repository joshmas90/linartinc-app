#!/usr/bin/env bash
set -euo pipefail

bash Scripts/ci_preflight.sh
bash Scripts/build_for_testing.sh
TEST_SUITE=unit bash Scripts/test_without_building.sh
TEST_SUITE=ui UI_TEST_RETRIES="${UI_TEST_RETRIES:-1}" bash Scripts/test_without_building.sh
