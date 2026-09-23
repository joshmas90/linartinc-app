# LINART for iPhone and iPad

A recreated native SwiftUI source project for Linart Construction Inc. Includes the existing website's branding, seven service pages, seven portfolio collections, offline photos, saved inspiration, a planning checklist, project inquiries, sharing, contact actions, service areas and privacy information.

## Open the project

1. Extract the ZIP on a Mac.
2. Open `LINART.xcodeproj` in Xcode 16 or later.
3. Select the shared `LINART` scheme. The deployment target is iOS 17.0; iPhone and iPad are supported.
4. For device signing or distribution, select your Apple Developer team in Signing & Capabilities. The proposed bundle identifier is `com.linartinc.LINART`; confirm availability in your Apple account before distribution.

There are no third-party runtime packages, API keys, project generators or package installation steps. The complete `.xcodeproj`, workspace metadata, shared scheme, test target, app icon and assets are included. Opening the project does not require regenerating anything.

## Features

- Native Home, Projects, My Project and About tabs.
- Searchable portfolio with full-screen, swipeable photo galleries.
- Saved projects and a preparation checklist persisted on the device.
- Optional private Project Studio: guided prompts, per-inquiry local drafts, verified online access, up to eight photos, ten inspiration URLs, conditional PDF document uploads, cloud saves and submissions, and manual PDF export. Hosted configuration and Xcode verification are required before release.
- Seven service detail pages and New Jersey service-area coverage.
- A native inquiry form matching the existing website's JSON contract.
- Input validation, explicit send consent, guarded submissions, visible errors and email/share fallbacks.
- Native phone, email and share actions; content works without a network connection except sending inquiries and opening external links.
- Dynamic Type, descriptive image labels, labeled actions and layouts that adapt to iPhone and iPad widths.

## Inquiry behavior

Requests go to `https://linartinc.com/contact.php` only after the user chooses Send inquiry. The app requires both a successful HTTP status and `ok: true` before showing success. It never silently retries. A timeout or network failure retains the entered details and explains that delivery is unconfirmed. Timing and description are optional, matching the current website handler. Changing a service CTA only changes the selected service, preserving the other draft fields.

Initial inquiry drafts live in memory and are cleared after confirmed success. Saved projects and checklist progress use local preferences. The optional Studio is a separate encrypted-at-rest local app-file draft containing photo copies and written planning details. The About screen can clear all local app data, including the Studio. Sending an inquiry is not appointment booking, a price quote or a guarantee of email delivery to an inbox. No live inquiry was submitted during reconstruction or audit.

The Studio now has source integration with the website repository's private PHP/Supabase backend. Entering photos or text keeps changes local; explicit online save/submission uploads them. Selecting a PDF sends it immediately only when server-side scanning is enabled. LINART can view online drafts. Manual sharing is separate. No online backend was deployed in this session; only the unrelated JCA Supabase project is currently connected.

## Project Studio status

See `Documentation/PROJECT-STUDIO-IMPLEMENTATION.md` and the website repository's release/deployment reports. The Studio has not been compiled or device-tested. Current verification records distinguish grammar/structure checks from Xcode tests; no static PASS means the app is release-ready.

## Verification status

Read `Documentation/AUDIT.md` and `Documentation/VERIFICATION.json` for the performed checks and their limits. The project was assembled and statically audited on Windows. **No Xcode build, simulator run, XCTest execution, signing, TestFlight upload or App Store submission was initiated.** The included XCTest cases use a mock URL protocol and do not send live inquiries; they are available for a later authorized Xcode test run.

## Before release

- Review the app on real iPhone and iPad devices, including large accessibility text sizes, rotation, offline browsing, and keyboard behavior.
- Run the included tests and complete an Xcode build when authorized.
- Configure your signing team, confirm the bundle identifier and version, and review current App Store requirements.
- Publish an owner-approved privacy policy URL for App Store Connect. The app includes a readable local privacy explanation and a privacy manifest; these do not publish a public privacy policy.
- Confirm the backend's availability and retention practices, inquiry delivery, branding, content and image rights.

## Provenance

The previous iOS ZIP could not be recovered from the accessible conversation or local files, and the app repository was empty when inspected. This is a new implementation, not an audited copy of the previous ZIP. Business content and images were recovered from `joshmas90/linartinc` at commit `45ee6b05b0148a226f7a97717df6aa25a35d5c29`. See `Documentation/AssetSources.json` for original image paths and hashes. The website's editorial homepage hero is retained as branding imagery and is not identified as a separately verified completed project.

`Scripts/verify_package.py` performs read-only structural checks and can also compare an extracted source directory with a ZIP. It uses Python 3.10+ and does not invoke Xcode or start a build.
