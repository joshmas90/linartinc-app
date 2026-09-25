# My Project refinements — September 25, 2026

The five-step planning flow now has six refinements:

1. A dedicated Verify & send screen, separate from submission history and account management. It retains email verification and explicit consent, resets consent when the draft or account changes, and shows a receipt for the exact successfully submitted snapshot. Old receipts are never used as a new success state. Account-history refresh no longer turns a successful send into a reported failure.
2. A project brief review that emphasizes supplied information, includes portfolio photographs, and collapses unanswered sections into optional additions. Every section remains editable with a direct return to review.
3. Project-specific example answers and photo guidance for kitchens, bathrooms, additions, whole-home renovations, new custom homes, basements and decks/patios, plus general guidance for other or undecided work. Selecting a type changes guidance only, never client answers.
4. Larger portfolio cards, distinct View project and Add to my brief actions, and a focused gallery inside planning. Viewing never adds an idea or changes tabs. Saved favorites remain first.
5. A current-step indicator rather than a completion percentage. Content summaries report actual photos, links, ideas and entered sections; skipping does not invent completed work.
6. Consistent My Project / project brief terminology across planning, sign-in, privacy guidance, inquiries, PDF copy and storage messages. Internal storage identifiers and persisted keys remain unchanged.

## Compatibility

Draft coding keys, schema version, local storage paths, Keychain identifiers, authentication protocol, upload payload and server endpoints are unchanged. New types are in existing Swift source files, preserving Xcode membership. Backend source, database configuration, signing, deployment settings and artwork are unchanged.

## Verification performed

- Parsed all changed Swift files with tree-sitter and compared errors against the parent revision: no new parse errors. The parser's existing limitation in CloudStudioClient's optional cast syntax is unchanged.
- Existing backend request/validation regression suite: 12 tests passed.
- Xcode project graph, Swift source membership, assets, JSON/plist/XML, privacy manifest and refreshed source SHA-256 manifest verified with Scripts/verify_package.py.
- git diff --check passed.

Native regression coverage was extended for contextual guidance preserving typed answers, viewing inspiration without adding it, deliberate inclusion, collapsed optional review sections, editing and returning directly to review, and a send screen without account-management controls. Model coverage also checks presentation helpers do not change persisted draft data.

## Native verification still required

This Linux environment has no Xcode or Apple SDK. The app has not been compiled, simulator-tested or device-tested for this revision; XCTest/UI tests were added but not executed here. Run the existing iPhone/iPad validation workflow before distributing a build. Check large text, keyboard layout, VoiceOver, photo import, PDF sharing, email-link return (warm and cold launch), consent reset, upload failures/retry and a real successful receipt. No live inquiry, sign-in email, upload, app build or release was initiated by this work.
