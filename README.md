# LINART for iPhone and iPad

Native SwiftUI source for Linart Construction Inc., supporting iOS 17+, iPhone and iPad. Retains the existing homepage, seven service pages, actual LINART portfolio collections, offline images, saved inspiration and planning checklist.

## Project Studio v1

The short inquiry is independent of the optional Studio. It requires name, email, phone, project location and project type; description, timing and preferred contact method are optional. No account, Studio questions, photos or budget is required to send the lead.

After confirmed acceptance, the client can begin Studio, return later or skip it. Email-code verification opens accepted inquiries securely. The Studio supports guided optional answers, photos, inspiration links, PDF plans, protected local drafts, private cloud saving and review-before-submit. Authorized staff review these records through the private website project desk.

See `Documentation/PROJECT-STUDIO-IMPLEMENTATION.md` for the actual source status and remaining checks. Backend source, SQL migration/rollback, deployment guide and independent integration tests are maintained in [joshmas90/linartinc](https://github.com/joshmas90/linartinc), under `docs/PROJECT-STUDIO-V1.md`, `server/`, `supabase/`, `tests/` and `apps/web/public/studio/`.

## Open and configure

Open `LINART.xcodeproj` in Xcode 16 or later and select the shared `LINART` scheme. No third-party runtime packages or project generator are required. Select the approved Apple team before device signing and confirm the proposed bundle identifier `com.linartinc.LINART`.

The app uses the existing `https://linartinc.com/contact.php` endpoint and the new `/studio/api.php` gateway. All Supabase credentials and privileged operations stay server-side. Deploy and verify the backend before releasing the cloud Studio.

## Current readiness

Source implemented and statically checked; **not Xcode-compiled, device-tested or deployed**. Only the unrelated JCA Supabase project is currently connected. A LINART target, private host configuration, SMTP/cron setup, approved migration and staging acceptance test are required.

No Codemagic build, signing, TestFlight upload or App Store submission was initiated. Source commits use `[skip ci]`. Do not automatically start a build or apply a production migration.

Run `python3 Scripts/verify_package.py --root .` for the read-only structural/source manifest check. Run the included XCTest suite later in an authorized Xcode test environment. A structural PASS is not build proof.

Before release, check iPhone/iPad layout, large text, VoiceOver, rotation, keyboard, offline behavior, file import, draft restore/conflicts, deletion and PDF export. Confirm approved privacy wording and App Store declarations against the deployed implementation.

## Content provenance

Branding and portfolio imagery originate from the website repository at `45ee6b05b0148a226f7a97717df6aa25a35d5c29`. `Documentation/AssetSources.json` records original image paths and hashes. The editorial homepage hero is retained as branding imagery, not asserted to be a separately verified completed LINART project. No new generated or stock portfolio imagery was introduced.
