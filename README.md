# LINART for iPhone and iPad

Native SwiftUI app for Linart Construction Inc., with an offline portfolio and a private project-planning Studio. This repository is the **app only**. The website is maintained separately; this revision does not change its source or deploy it.

## Build and test

Open `LINART.xcodeproj`, select the shared LINART scheme, and use Xcode 26.6. The deployment target is iOS 17.0. Select the existing signing team for physical devices. App identifier: `com.linartinc.LINART`.

There are no third-party runtime packages. The app contains a public Supabase publishable key, never SMTP credentials, signing material, or a server/service-role key.

On macOS run `bash Scripts/validate_ios.sh`; set `SIMULATOR_FAMILY=iPad` for the tablet pass. It verifies the source package and executes unit/UI tests, saving logs and an `.xcresult` bundle. GitHub Actions runs both families. Codemagic's manual App Store workflow requires the same validation before signing or uploading.

`python Scripts/verify_package.py --root .` checks the project graph, assets, manifests, and package hashes. `node --test Backend/*.test.mjs` runs backend tests with Node 24. These commands alone do not prove native compilation or real-device behavior.

## Features

- Ivory/brass Home with an AI-refined kitchen hero based on LINART photography and a clean handoff from the existing welcome artwork.
- Seven project collections, seven services, searchable offline galleries, pinch/double-tap zoom, project-specific sharing, saved ideas and notes.
- Guided My Project: five numbered steps, Back/Continue/Skip controls, resume at the last step, and direct edits from the final review.
- One shared draft for project details, photos, portfolio inspiration, web links, budget and timing; sharing begins only after review and explicit confirmation.
- Protected, versioned local files, ordered background saves, recovery of a previous draft, visible storage errors, and reset protection against delayed work.
- Up to eight selected photos, normalized to 1600 pixels with metadata removed and small editing thumbnails.
- Multipage project-book and summary PDFs with complete answers/captions, protected temporary exports and cleanup.
- Three-step inquiry with focusable validation, consent and optional local draft saving. The existing contact.php contract is preserved, with no silent retry.
- Optional email-link sign-in and direct Studio submission to an app-specific Supabase service, verified ownership, private photos and stable receipts.
- Individual cloud-upload deletion and in-app account-deletion requests. Shared sign-in removal requires LINART review; see Backend/README.md.
- Local support diagnostics containing error categories rather than customer content.

## Data boundaries

Ordinary browsing and local planning upload nothing. The user explicitly sends either an inquiry to the existing website endpoint, a Studio to the separate app backend, or a PDF through a chosen sharing app. These are distinct actions and success states. A Studio receipt confirms storage, not an appointment or response. Website inquiries and Studio receipts are not automatically linked.

The owner's existing paid Supabase project is reused. App tables/bucket use linart_ios_ / linart-ios- names. Existing LINART tables, policies and website source remain unchanged. Authentication and SMTP are shared project services. The owner confirmed Hostinger sign-in email delivery on September 25, 2026.

## Current evidence and release checks

Documentation/GUIDED-MY-PROJECT.md tracks the latest navigation revision and its validation limits. Documentation/2026-09-25-AUDIT-REVISIONS.md describes the preceding audit. Earlier results do not verify the new guided flow. Consult the exact commit's GitHub Actions results for native evidence.

Before public release: complete physical-device sign-in/upload/delete and share-sheet checks; verify iOS 17, small screens and accessibility text; update App Store privacy disclosures for photos/user content/user ID; publish the app privacy policy. LINART must monitor account-deletion requests and fulfill the seven-day target. No public App Store release is performed by the audit branch.

## Provenance

The audited source matched b8b805d54fa3dad12f2f6d56cad7fbb386f4e087; the supplied IPA was version 1.0.0, build 11. Existing photo provenance is in Documentation/AssetSources.json. Generated welcome artwork is decorative and is not completed-project evidence. Source and runtime assets are covered by MANIFEST.sha256.
