# Project Studio v1 — source implementation

Updated September 23, 2026. **Not yet compiled or device-tested. Not deployed.**

The optional Studio now connects to the PHP/Supabase gateway implemented in the separate `joshmas90/linartinc` website repository. See that repository’s `docs/PROJECT-STUDIO-V1.md` for backend design, migration, configuration, privacy, test evidence and release gates.

Implemented native behavior:

- The original short inquiry remains independent. A stable request UUID enables server replay protection; uncertain delivery retains details and does not retry automatically. Contact preference is optional.
- Confirmed inquiry acceptance offers begin, later and skip choices. The project tab provides a passwordless return-access screen; access to a project requires an accepted inquiry and verified email.
- Email OTP login, device-only Keychain access token, sign-out/reverification, verified project selection and project-scoped protected local drafts. Cached project listings support local editing during an outage when a local session was available.
- Existing service-specific prompts and LINART photography/branding retained, with progressive disclosure for design, investment and constraints.
- Eight locally normalized 1600-pixel JPEG photos with captions; ten web links with notes; four optional PDFs up to 10 MB each. Server validation remains authoritative. PDFs require a configured safety scanner; photos of plans are the fallback.
- Explicit cloud-save consent and a separate review-before-submit action. Partial briefs are valid. Cloud drafts are visible to authorized staff; submitting marks a brief ready for review.
- Version checks reject stale answer overwrites. New devices can restore cloud answers/files; reload warns before replacing an existing local draft. Uploads may complete before a later save fails, so error copy asks the client to refresh before retrying.
- Cloud file removal on the next save, client account/cloud-project deletion, local clearing, and updated privacy explanations/declarations.
- PDF export remains optional and does not claim external delivery. Long answers paginate; document plans are listed rather than embedded. Temporary exported PDFs are removed when the share sheet closes.

Configuration:

- The app calls `https://linartinc.com/contact.php` and `https://linartinc.com/studio/api.php`.
- No Supabase URL, service-role key, secret key or staff credentials belong in the app.
- Backend deployment must precede a released app with cloud Studio enabled. The production backend has not been installed by this change.
- The connected Supabase account currently exposes only JCA. A confirmed LINART target and approved migration are still needed.

Verification:

- Swift syntax parsing, project source/resource membership and package structure checked. These do not replace Swift type checking.
- Backend contracts tested separately using a local PHP server, fake HTTPS Supabase, isolated PostgreSQL engine and mail sink. No real client or production email was sent.
- Additional XCTest cases cover stable inquiry IDs, cloud payload separation and per-project storage isolation. They have not been executed here.
- Xcode compile, XCTest, iPhone/iPad simulator and device tests, Dynamic Type/VoiceOver, keyboard/safe areas, import/restore, long-PDF pagination and interrupted uploads remain mandatory release gates.
- No Codemagic build, signing, TestFlight upload, App Store submission or production database migration was started.

Do not treat the original `Documentation/AUDIT.md` as verification of this revision. Current checks and limits are recorded in `Documentation/VERIFICATION.json` and the source manifest is recomputed from current files.
