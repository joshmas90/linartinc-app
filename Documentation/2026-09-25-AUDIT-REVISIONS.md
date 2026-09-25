# September 25, 2026 app audit revisions

Baseline: b8b805d54fa3dad12f2f6d56cad7fbb386f4e087, version 1.0.0/build 11. The full baseline audit is delivered separately as LINART-iOS-Audit.html/.md. This document tracks implementation and supersedes earlier verification-status paragraphs for the audit branch.

## Resolution register

| Finding | Revision |
|---|---|
| A01 shared draft/reset races | One app-owned StudioStore; generation/revision guards; pending saves/imports/exports cancelled on reset; actor rejects stale operations. |
| A02 photo scale/metadata | ImageIO pixel normalization at 1600 maximum; 240-pixel thumbnails; metadata removed; byte/pixel tests. |
| A03 clipped long PDF text | CoreText frame pagination across arbitrary paragraphs; regression checks final long-answer and caption markers. |
| A04 corrupt draft overwritten | Versioned envelope, explicit unavailable state, legacy migration, preserved corrupt original and recoverable previous save. |
| A05 foreground/every-key I/O | Debounced ordered actor persistence; background photo normalization, thumbnails and PDF work; explicit local save state. |
| A06 inconsistent clearing | Shared async clearing from Settings; errors remain visible; older operations cannot recreate cleared data. |
| A07 lingering exports | Protected temporary export files; share-completion cleanup, aged-file cleanup and reset cleanup. |
| A08 export errors behind sheet | One review destination, visible export failure, share sheet only after successful PDF preparation. |
| A09 inquiry error navigation | Three guided steps with labels, focus/scroll to first invalid field and accessibility announcement. |
| A10 network handling | Offline and cancellation classification, 429 Retry-After handling, preserved fields and no automatic inquiry retry. |
| A11 release test gate | Xcode 26.6 pinned; source verification + unit/UI checks on phone/tablet; Codemagic test failure stops archive/upload. |
| A12 generic sharing | Share the actual selected project image, title, location and scope with the existing site link. No fabricated deep-link destination. |
| V01 welcome handoff | Keep existing artwork/Skip/accessibility behavior; shorter transition with underlying content hidden until handoff. |
| V02 Home composition | Ivory text/action area separate from a curated real bathroom photo. Generated welcome image stays decorative. |
| V03 contact targets | Explicit 44-point minimum controls. |
| V04 floating tab overlap | Native safe areas retained; simulator/gallery/large-text checks document whether actions remain reachable. Physical-device confirmation remains required. |
| V05 Studio prominence | Studio leads My Project, with saved ideas/checklist as supporting content. |
| V06 photo destinations | Unified library with purpose filters and import purpose captured before asynchronous work. |
| V07 review duplication | One structured preview of answered topics, photos, ideas and links; PDF format and direct-send actions. |
| V08 portfolio craftsmanship | Zoom, captions, existing scope/location/stage, selected-project sharing and private notes on included ideas. No invented case-study facts. |

Premium additions include project-book/summary PDFs, opt-in inquiry saving, typed tabs, saved inspiration in the Studio, local support diagnostics, and optional private app submissions with verified email, stable receipts and deletion controls. Native text editing retains its standard editing/undo behavior. A dark theme and invented project narratives were not introduced.

## Backend and service evidence

The existing paid Supabase project is reused with app-specific tables, private bucket and Edge Function. No website source, existing LINART table or existing policy was edited. Authentication/SMTP are shared project services. The owner saved Hostinger SMTP credentials directly; the owner confirmed arrival of the one authorized test sign-in email.

Twelve backend tests pass locally. Rollback-only live SQL checks pass for ownership, grants, receipts, private storage, quotas and deletion isolation. Missing/invalid bearer requests return 401. The shared project's existing leaked-password-protection warning remains; the app uses email links. See Backend/README.md for operating responsibilities and the advisor remediation link.

Automatic approval review rejected a permanent shared Auth-user deletion path because that irreversible behavior was not specifically authorized. The implemented alternative removes app uploads and records an account-deletion request; LINART must fulfill those requests within seven days. No user account was deleted during this audit.

## Native validation and limits

Twenty unit tests passed on both iPhone Air and iPad mini simulators with Xcode 26.6. The UI suite additionally exercises Studio editing/review, inquiry validation, reset, landscape and accessibility text. The exact branch commit's GitHub Actions run is the authoritative final status; intermediate runs exposed and corrected a Keychain compile error and UI-test selector differences.

Windows cannot execute the signed iOS app. The owner-supplied recording covers the baseline, not the revised build. Physical-device email callback, real photo import/share destinations, interrupted live upload/delete and iOS 17 behavior remain release checks. These are not claimed as tested by a server receipt or a passing source-package check.

## Privacy and release

PrivacyInfo.xcprivacy now declares uploaded photos, user content/user ID and file timestamps used for cleanup in the app container (C617.1), alongside UserDefaults (CA92.1). Update the corresponding App Store Connect privacy answers. A readable app-specific policy is provided in APP-PRIVACY.md without modifying the website.

Apple references: https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype and https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons . Account-deletion guidance: https://developer.apple.com/support/offering-account-deletion-in-your-app .

No public release or website deployment has been made. Merge/build/release decisions must use the final passing commit and complete the remaining device/operating checks above.
