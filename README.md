# LINART for iPhone and iPad

A recreated native SwiftUI source project for Linart Construction Inc. Includes the existing website's branding, seven service pages, seven portfolio collections, offline photos, saved inspiration, a planning checklist, project inquiries, sharing, contact actions, service areas and privacy information.

## Open the project

1. Extract the ZIP on a Mac.
2. Open `LINART.xcodeproj` in Xcode 16 or later.
3. Select the shared `LINART` scheme. The deployment target is iOS 17.0; iPhone and iPad are supported.
4. For device signing or distribution, select your Apple Developer team in Signing & Capabilities. The proposed bundle identifier is `com.linartinc.LINART`; confirm availability in your Apple account before distribution.

There are no third-party runtime packages, API keys, project generators or package installation steps. The complete `.xcodeproj`, workspace metadata, shared scheme, test target, app icon and assets are included. Opening the project does not require regenerating anything.

## Features

- Native Home, Projects, Services, My Project and More tabs.
- LINART welcome on each fresh app launch, with bundled project photography, five coordinated effects, immediate Skip and an optional Replay welcome action in Settings. Returning from the background and changing pages do not replay it. See `Documentation/FIRST-LAUNCH-INTRODUCTION.md` for timing and device checks.
- Reference-inspired ivory/brass styling, responsive native hero text, portfolio category filters, image-first galleries and service pages.
- A Project Studio menu with focused photo, inspiration, project-detail, budget/timing and review screens.
- Searchable portfolio with full-screen, swipeable photo galleries.
- Saved projects and a preparation checklist persisted on the device.
- Optional private Project Studio: guided prompts, up to eight device-selected photos, up to ten inspiration URLs, on-device draft storage and a reviewable photo-inclusive PDF export.
- Seven service detail pages and New Jersey service-area coverage.
- A native inquiry form matching the existing website's JSON contract.
- Input validation, explicit send consent, guarded submissions, visible errors and email/share fallbacks.
- Native phone, email and share actions; content works without a network connection except sending inquiries and opening external links.
- Dynamic Type, descriptive image labels, labeled actions and layouts that adapt to iPhone and iPad widths.

## Inquiry behavior

Requests go to `https://linartinc.com/contact.php` only after the user chooses Send inquiry. The app requires both a successful HTTP status and `ok: true` before showing success. It never silently retries. A timeout or network failure retains the entered details and explains that delivery is unconfirmed. Timing and description are optional, matching the current website handler. Changing a service CTA only changes the selected service, preserving the other draft fields.

Initial inquiry drafts live in memory and are cleared after confirmed success. Saved projects and checklist progress use local preferences. The optional Studio is a separate encrypted-at-rest local app-file draft containing photo copies and written planning details. The About screen can clear all local app data, including the Studio. Sending an inquiry is not appointment booking, a price quote or a guarantee of email delivery to an inbox. No live inquiry was submitted during reconstruction or audit.

The Studio does not transmit photos or notes to the website server automatically. The user can export a PDF and choose a sharing destination, including emailing it manually to services@linartinc.com; the app does not verify that this share was delivered. The current contact.php API supplies no authenticated inquiry reference or secure follow-up/photo-upload endpoints, so Studio details are **not automatically associated with the original inquiry**. Such server integration requires a separate, authorized backend implementation. The website backend is maintained separately. No server credentials, contact logs or backend deployment files are included. The source does not include customer accounts, payments, scheduling, push notifications or a client job-status portal because those are not available in the reference website.

## Project Studio status

The Studio code was added after the original static audit report. Its photos, local persistence, PDF export and optional post-inquiry invitation have **not** been compiled or device-tested. The original verification PASS in Documentation/VERIFICATION.json applies only to the pre-Studio revision. See Documentation/PROJECT-STUDIO-IMPLEMENTATION.md for outstanding backend and release requirements.

## September 24 visual revision

The reference-inspired app redesign and clipped-hero fix are documented in `Documentation/PREMIUM-REFERENCE-REVISION.md`. Syntax and package checks were performed on Linux; this revision still needs an Xcode compile and on-device visual review. No automatic build or Apple upload was started.

## Verification status

Read `Documentation/AUDIT.md` and `Documentation/VERIFICATION.json` for the performed checks and their limits. The project was assembled and statically audited on Windows. **No Xcode build, simulator run, XCTest execution, signing, TestFlight upload or App Store submission was initiated.** The included XCTest cases use a mock URL protocol and do not send live inquiries; they are available for a later authorized Xcode test run.

## Before release

- Review the app on real iPhone and iPad devices, including large accessibility text sizes, rotation, offline browsing, and keyboard behavior.
- Run the included tests and complete an Xcode build when authorized.
- Configure your signing team, confirm the bundle identifier and version, and review current App Store requirements.
- Publish an owner-approved privacy policy URL for App Store Connect. The app includes a readable local privacy explanation and a privacy manifest; these do not publish a public privacy policy.
- Confirm the backend's availability and retention practices, inquiry delivery, branding, content and image rights.

## Provenance

The previous iOS ZIP could not be recovered from the accessible conversation or local files, and the app repository was empty when inspected. This is a new implementation, not an audited copy of the previous ZIP. Business content and images were recovered from `joshmas90/linartinc` at commit `45ee6b05b0148a226f7a97717df6aa25a35d5c29`. See `Documentation/AssetSources.json` for original image paths and hashes. The original website banner remains bundled for provenance but is no longer displayed by the homepage. The app uses the existing kitchen-remodeling photograph with native, wrapping text and a working button.

`Scripts/verify_package.py` performs read-only structural checks and can also compare an extracted source directory with a ZIP. It uses Python 3.10+ and does not invoke Xcode or start a build.
