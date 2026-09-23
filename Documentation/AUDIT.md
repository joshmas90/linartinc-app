# Reconstruction and static audit

Date: 2026-09-23

## Source recovery

The referenced conversation was read. Its assistant responses were exposed only as content-reference markers, and it provided no recoverable attachment. No native LINART iOS archive was found among accessible LINART downloads. The local synced project sources directory was empty. The dedicated `joshmas90/linartinc-app` repository had no Git refs when inspected. Consequently there was no previous native source to compare or repair.

This package is a fresh native SwiftUI implementation grounded in the accessible website source at commit `45ee6b05b0148a226f7a97717df6aa25a35d5c29`.

## Configuration and code decisions

- Included a complete conventional Xcode project with explicit source and resource references, Debug and Release configurations, a shared scheme, an application target and a hosted XCTest target.
- iOS 17.0 minimum, iPhone and iPad device families, Swift 5 language mode, no external runtime dependencies or automatic build workflows.
- Signing uses Automatic configuration with no hard-coded development team or signing certificates. The Apple account owner must choose a team for device distribution.
- Included a launch background, opaque 1024-pixel app icon, Info.plist, privacy manifest and bundled content catalog. Info.plist is not copied into the resources build phase.
- Converted the website's WebP photographs to native JPEG asset-catalog images, removing EXIF metadata and limiting the longest edge to 1600 pixels. Original branding is retained. All browsing images are local assets.
- Preserved the server's allowed service values and optional timing/description fields. Validated required fields and server length limits. User-entered strings are encoded as JSON and email URL query items.
- No live request is made while opening or browsing the app. Explicit form consent and Send inquiry are required. Submission locks the form; failures retain the draft; HTTP failure, `ok: false`, malformed JSON and network failures do not show success.
- The network session is ephemeral with bounded timeouts and no automatic app-level retry. No transport-security exception, embedded secret, account login, analytics SDK or unnecessary permission is included.
- Local preference access is declared in the privacy manifest with reason CA92.1. Inquiry data collection is declared for app functionality and not for tracking. The local privacy screen describes the backend's existing request logging and email behavior.
- Saved project identifiers and checklist steps persist locally and can be cleared. Contact details are not deliberately persisted by the app. Inquiry drafts are memory-only.

## Checks performed

The machine-readable `VERIFICATION.json` records static audit results. The audit checks all source/resource references and build phases, shared-scheme target references, JSON/XML/plist validity, every bundled image's readability, catalog IDs and image links, opaque icon dimensions, privacy declarations, endpoint and server-option parity, and absence of unexpected binary/build/secret files. Swift files are parsed with tree-sitter-swift as a syntax check; this is not Apple compiler type checking.

The downloadable ZIP is then reopened, decompressed and CRC-tested. Every payload path and SHA-256 digest is compared against the source and the included `MANIFEST.sha256`. The archive has one top-level `LINART-iOS` folder and contains no `.git`, dependency caches, website clone, user settings, credentials or build products.

## Limits and release work

No Xcode build, Apple compiler type checking, simulator run, XCTest execution, signing, TestFlight or App Store operation was performed. No live form POST or test email was sent. Visual layout and OS integration require a later device/simulator pass. Static parsing cannot establish runtime behavior or App Store approval.

The included tests cover inquiry validation and encoding, persistence/clearing, bundled catalog integrity, and mocked success, rejection, rate limiting, malformed responses and offline errors. They remain unexecuted as requested because running the hosted suite would initiate an iOS build.

Before release, the owner must confirm signing and bundle-ID availability, inspect the UI on devices, authorize a build/test pass, verify live inquiry delivery, approve image rights and supply a published privacy-policy URL. The existing backend determines retention and email routing; this package does not change it.

## Apple references used

- [Required-reason API declarations](https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest)
- [Collected data types](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype)
- [App icon configuration](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
