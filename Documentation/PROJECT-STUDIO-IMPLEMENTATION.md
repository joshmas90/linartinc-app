# LINART Project Studio v1 — current source status

Updated 23 September 2026. This supersedes the earlier local-only Studio implementation notes. **Source is prepared for staging; hosted deployment, Xcode compilation and device acceptance remain incomplete.**

## Client experience

1. Explore LINART's existing services and actual portfolio photography.
2. Send a short inquiry: name, email, phone and location required; project type selected; timing, preferred contact and description optional. No budget, uploads or account sign-in is required.
3. Only a confirmed endpoint success opens the thank-you screen. Begin optional Studio, return later, or finish without it. Inquiry delivery does not depend on Supabase.
4. The inquiry's private receipt is saved in Keychain. A project-specific local draft can be used immediately; online access uses a one-time email code plus the receipt. No password is created by the client.
5. Explore service-specific questions, existing conditions, layout/priorities, style/materials, constraints, optional investment/timing, selected photos with notes, and up to ten inspiration links. Every question remains optional. The details/link sections disclose progressively.
6. Local changes save automatically to protected, per-inquiry files. Save online explicitly uploads the photos/answers/links; LINART can review online drafts. When server scanning is configured, selecting a PDF uploads it privately; the UI states this before file selection.
7. Review the written brief and photos, including saved online photographs; submit a complete or partial brief. The backend confirms the submission and stores the submitted snapshot/time. Manual PDF export remains separate and does not imply delivery.
8. Return with a new email code, select the correct project, reload the online brief if needed, edit, and submit an update. Conflicting revisions require a reload; a stale local draft cannot silently replace newer server answers.

## Native implementation

`Services/StudioClient.swift`: ephemeral URLSession transport, no automatic retries, multipart uploads, typed server responses, Keychain access token/receipt storage. No Supabase URL/key or service-role secret in the app. Endpoint is LINART's own HTTPS PHP gateway.

`Views/PlannerView.swift`: private access/return screen, per-inquiry local folders, explicit online save/submission, selected-photo upload and captions, private remote-photo previews, optional PDFs, deletion requests, and local PDF fallback. Existing service-specific prompts and restrained LINART design tokens are retained. Photo rendering is normalized at 1x so device screen scale cannot unexpectedly triple upload dimensions. Long PDF text is split into bounded chunks before pagination. Exact visual parity with previous mockup images remains unverified because the image files were unavailable.

`InquiryClient`/`Inquiry`: backward-compatible success decoding plus request identity and optional receipt fields. A request UUID persists for that in-memory inquiry; the backend rejects changed-content reuse and replays accepted requests without another email. Unknown network/server results display unconfirmed-delivery guidance and disable resubmission in the current form.

Local online revision metadata persists with the draft. New-device users must load the online version before replacing an existing brief. Online attachment removal is separate from clearing the local draft. Clearing all local app data removes all project folders and Keychain credentials. Online deletion requests close client access immediately and require LINART's operational fulfillment.

## Backend and admin

Source lives in the website repository `joshmas90/linartinc`, branch `work/project-studio-v1`. See its `docs/PROJECT-STUDIO-PLAN.md`, `docs/PROJECT-STUDIO-DEPLOYMENT.md`, `docs/PROJECT-STUDIO-RELEASE-READINESS.md` and `docs/PRIVACY-POLICY-DRAFT.md`.

The connected Supabase account currently exposes only JCA. That unrelated database was untouched. A dedicated LINART project and staging environment must be connected/approved before deployment. A functioning hosted Studio is **not** claimed by this source delivery.

## Verification and outstanding gates

Performed: Swift grammar parse, Xcode project/resource structure audit, current privacy plist parsing and key validation against Apple documentation, website release build, changed JavaScript lint, PHP syntax checks, and isolated database/inquiry/gateway/validator tests in the website repository.

Not performed: Swift type checking with the Apple SDK, Xcode build, XCTest execution, simulator/physical iPhone/iPad runs, live Supabase Auth/Storage integration, production email verification, signing, TestFlight, Codemagic or App Store submission. The included XCTest cases were updated for request IDs and online response decoding; they require an approved Mac test run.

Before release test large Dynamic Type/VoiceOver, iPhone/iPad portrait/landscape, keyboard focus, local-save failure, code expiry, inquiry timeout, offline drafts, two-device conflict, photo picker and metadata removal, document scanner rejection/recovery, PDF pagination/sharing/cleanup, deletion handling, and administrator role revocation. Final privacy policy publication and retention schedule require owner approval.
