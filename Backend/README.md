# App-only Studio service

Project: existing paid LINART project sembxmcpuildyloqjhfj. No additional project/subscription was created. The website repository and four existing LINART tables were not edited.

## Components

- schema.sql: app submissions/photo manifests, private bucket, owner-only reads, service-only mutation/receipt functions and live-session verification.
- account-deletion.sql: private deletion requests, idempotency and a transactional block on new submissions while deletion is pending.
- functions/linart-ios-api: confirmed Supabase Auth identities. Gateway JWT checking is disabled because the function verifies bearer tokens through Auth and checks the live session itself. Never remove those checks.

These migrations are already applied. Do not rerun creation scripts in production; use a new migration for future changes.

## Limits and retries

Eight JPEG photos, 5 MB each; a 100 KB brief; ten links; at most five retained submissions created in the last day and twenty total retained submissions per user. Removing a submission frees capacity. These are storage bounds, not a complete anti-abuse system. Supabase handles email throttles.

An unchanged retry reuses the pending ID and payload hash saved in Keychain. Existing upload bytes are checked before a retry is accepted. Finalization verifies all expected photo hashes/sizes and returns a stable receipt. A changed brief starts a new reference. Users can delete incomplete uploads; there is no automatic server-retention job.

## Reviewing submissions

In the LINART Supabase Table Editor, open linart_ios_submissions. Submitted rows are complete; draft rows are incomplete. Attachment records identify objects in private bucket linart-ios-studio. Only authorized LINART administrators may retrieve them. Never place server keys in clients or support messages.

The app does NOT email staff when a Studio arrives. Staff must review this queue. A receipt promises storage only. Existing website inquiry notifications remain unchanged.

## Account-deletion requests: LINART responsibility

Delete my app account closes new uploads, removes app submission rows/photo objects, and records a stable request in linart_ios_deletion_requests. A storage failure is reported and references remain available for retry. Local Studio data stays until the customer clears it.

LINART must monitor this table, finish requests within 7 days and confirm completion by email. This target was selected after the owner delegated the decision. It is a staff responsibility, not an automated completion claim. Do not publicly release the account feature without assigning someone to this queue.

Shared Supabase Auth identities are not automatically removed: they may be referenced by existing inquiries, submissions or staff access. Automatic approval review rejected adding a permanent Auth deletion path without specific authorization. Review shared relationships and retention requirements when fulfilling a request. Do not delete/rewrite website records as part of this app audit. Mark completed_at only after fulfillment and customer confirmation. If an identity is subsequently removed, the request retains an anonymous reference.

No customer account was deleted. No staff notification or scheduled monitor was created.

## Verification

- Node tests mock external services and check bounded inputs, unsafe links, hashes, ownership filtering, revoked sessions, quotas, app-only deletion and partial failures.
- verify.sql uses generated .invalid fixtures in a rollback-only transaction. Checks RLS, grants, receipts, bucket privacy, quotas, deletion isolation and the upload block; sends no email and leaves no fixtures.
- Live missing/invalid bearer requests return 401.
- One authorized Hostinger sign-in email arrived. This proves delivery, not the physical-device callback/upload flow.
- Security advisor has no new table/function findings. The shared project still warns that leaked-password protection is disabled. The app uses passwordless links. Remediation: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## Device verification before release

Request a NEW link from the installed app, open it on that device, submit a disposable brief/photo, retry unchanged, verify one receipt, and delete it. Check interrupted connectivity and cancellation. The earlier delivery-test link has no device PKCE verifier and cannot prove app sign-in. Inspect the app-specific private bucket after the test. Complete the manual account-deletion operating process before launch.
