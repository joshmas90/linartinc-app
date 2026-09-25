# LINART build, validation and release pipeline

## Purpose

LINART uses separate CI and release-certification stages so a UI-regression failure is not confused with a compile, signing or App Store packaging failure. Required checks remain blocking: no release workflow reaches signing unless its preflight, compilation, unit-test and release-smoke gates pass.

## Validation stages

### 1. Source preflight

`Scripts/ci_preflight.sh`:

- verifies the Xcode project graph, resources, privacy manifest and SHA-256 source manifest;
- runs backend request/validation tests when `RUN_BACKEND_TESTS=1`;
- records the exact Xcode version and available simulators;
- selects one simulator on the required iOS major runtime and writes its identity to `build/simulator.env`.

Xcode is pinned by CI configuration to 26.6. The simulator runtime is pinned to iOS 26.x. A specific device name can additionally be pinned with `SIMULATOR_NAME`; if that requested device is unavailable, selection fails rather than silently switching devices.

### 2. Native compilation

`Scripts/build_for_testing.sh` runs `xcodebuild build-for-testing` once. This separates compiler/project failures from test failures and produces one DerivedData tree reused by later test gates.

### 3. Tests without rebuilding

`Scripts/test_without_building.sh` reuses the compiled test products.

Supported `TEST_SUITE` values:

- `unit`: the complete `LINARTTests` target. No retry.
- `smoke`: the small release UI certification covering launch, My Project, large text, reset, navigation, empty-plan safety and draft resume.
- `ui`: the complete `LINARTUITests` regression target.
- `all`: all scheme tests.

UI suites may retry once when `UI_TEST_RETRIES=1`. The first failed `.xcresult` and log remain artifacts. A second failure blocks the workflow. Unit-test failures are never retried.

### 4. Automatic main-branch certification

`.github/workflows/ios-validation.yml` runs on:

- every push to `main`;
- pull requests;
- manual dispatch.

It validates two independent environments:

- iPhone certification: preflight + backend + compile + native unit tests + full UI regression;
- iPad regression: preflight + compile + full UI regression.

Logs, simulator metadata, `.xcresult` bundles and screenshots are retained as workflow artifacts.

### 5. CodeMagic App Store release

The manual `linart-app-store-upload` workflow performs:

1. release-configuration checks;
2. source/backend/simulator preflight;
3. one native compile-for-testing;
4. complete native unit tests;
5. release UI smoke certification;
6. App Store profile application;
7. Release archive and IPA export;
8. bundle ID, build number, code-signature and Apple Team ID verification;
9. App Store Connect publishing handoff.

The signing and archive stages cannot execute after a required validation gate fails.

The full UI regression belongs to automatic CI on the exact `main` commit. The release workflow intentionally runs the shorter smoke suite again as an independent last-mile certification before signing.

## Local/manual validation

Full iPhone validation:

```bash
bash Scripts/validate_ios.sh
```

Full iPad validation:

```bash
SIMULATOR_FAMILY=iPad bash Scripts/validate_ios.sh
```

Individual stages:

```bash
bash Scripts/ci_preflight.sh
bash Scripts/build_for_testing.sh
TEST_SUITE=unit bash Scripts/test_without_building.sh
TEST_SUITE=smoke bash Scripts/test_without_building.sh
TEST_SUITE=ui bash Scripts/test_without_building.sh
```

## Failure classification

The stage name is the failure class:

- **Preflight failed** — package/project/privacy/backend/simulator issue.
- **Compile failed** — Swift/Xcode/project build issue.
- **Unit tests failed** — deterministic model/service/persistence regression.
- **UI smoke failed** — critical release interaction regression.
- **Full UI regression failed** — broader iPhone/iPad interaction/accessibility regression.
- **Signing failed** — provisioning/certificate/team issue.
- **IPA verification failed** — bundle/build/signature identity mismatch.

This separation is intentional: an XCUITest accessibility failure should never be reported as though code signing or IPA creation failed.
