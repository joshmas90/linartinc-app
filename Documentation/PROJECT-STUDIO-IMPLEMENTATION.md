# Optional LINART Project Studio — implementation status

Updated September 23, 2026. This is an **app-source change only**. No iOS build, simulator test, live inquiry, automatic publishing, or backend deployment was performed.

## Delivered in the app repository

- The initial inquiry still requires name, email, phone and project location. The existing `contact.php` request is unchanged and must complete independently of any Studio activity.
- **Only after a confirmed initial inquiry**, the thank-you screen offers an optional path to My Project. The client can finish without adding details.
- My Project now opens the private Project Studio. It includes project-type-specific prompts, existing-space notes, optional design/priorities/budget/timeline prompts, up to eight device-selected photos, photo notes, up to ten web inspiration URLs and optional URL notes.
- A draft is saved under the app's Application Support directory using protected local files. Imported images are resized, converted to JPEG and stripped of source metadata in the new copy. No photo picker selection or typed Studio text triggers any network request.
- A client can review the brief, generate a PDF containing their answers, links and all available photos, and explicitly choose a destination from the iOS share sheet. The client must select an email app, address it to `services@linartinc.com`, and send. The app cannot confirm external delivery. The PDF lives in temporary storage and may remain there until the OS purges its temporary files.
- The user can clear the Studio draft/photos directly, or clear all local app data in About. Initial inquiry data remains separate.

## Not delivered yet — server work

The existing `contact.php` contract does **not** supply an authenticated inquiry identifier, photo-upload endpoint, or secure invitation. The PDF sharing flow is a manual fallback, **not** a backend-linked project submission. The app must not imply that photos or notes have reached LINART just because the PDF was prepared or the share sheet was shown.

A connected, contractor-facing Studio needs an approved server design and deployment with:
1. A unique inquiry ID returned when the initial inquiry is accepted. Keep its existing fast-submit behavior and response compatibility.
2. Expiring, single-client invitation tokens or another strong authorization design; never expose one client's project data to another.
3. Private image storage, limits and content validation on the server, safe file naming, malware scanning where available, explicit media consent and retention/deletion policy.
4. Idempotent follow-up submission associated with the original inquiry, with an accessible contractor inbox/dashboard and verified notification delivery.
5. Security testing, documented privacy policy, access controls, recovery and deletion processes.

## Verification needed before release

Run Xcode type checking and compilation, the existing XCTest suite, simulator and physical iPhone/iPad layout checks, import and remove photo tests, long-response PDF pagination tests, app-restart persistence tests, offline sharing tests, VoiceOver/Dynamic Type checks, and initial inquiry delivery checks. Inspect the PDF recipient experience using real email apps. An initial inquiry must succeed even if the Studio is skipped, closed, interrupted, or cannot save locally.

`Documentation/VERIFICATION.json` and `MANIFEST.sha256` were generated for the original reconstructed source **before** the Studio edits. Their PASS/digests must not be treated as verification of the current repository revision. Regenerate both after the full app/build audit; do not modify old digest values without recomputing them.
