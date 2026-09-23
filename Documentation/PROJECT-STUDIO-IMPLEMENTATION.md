# LINART Project Studio implementation

The initial inquiry must remain independent and complete after `contact.php` returns an accepted response. Name, email, phone, and project location remain required; the studio is never required. After acceptance, offer an optional follow-up and a skip action.

Client-side draft: collect existing-space photos, inspiration photos, cited inspiration URLs, optional notes, project-specific prompts, priorities, budget and timing. Let the client review and explicitly share the brief. Do not upload files automatically.

Backend dependency: the existing `contact.php` contract does not expose an authenticated client project ID, upload endpoint, or secure invitation. Do not imply photos or follow-ups are linked to the original inquiry until the website backend implements authenticated invitation tokens, private object storage, attachment validation and quotas, server-side inquiry association, retention/deletion, and an authorized contractor view.

No automatic builds or uploads are initiated by this documentation change.
