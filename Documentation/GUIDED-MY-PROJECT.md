# Guided My Project — September 25, 2026

The planning menu has been replaced with a sequential client journey:

1. Your project — choose a project type and describe the space; additional questions are expandable.
2. Photos of your space — select up to eight photos, add captions, or skip.
3. Ideas & inspiration — add web links and select LINART portfolio projects within the planner.
4. Budget & timing — optional expectations, with examples and permission to be undecided.
5. Review & send — review the complete brief, edit any section and return directly to review, then choose to send or save for later.

## Navigation and behavior

- My Project has one primary Start/Continue action and an optional list of all steps.
- Step count, plain-language guidance, Back, Continue and Skip appear throughout.
- The bottom controls respect safe-area layout, stack for accessibility text sizes, and yield to the keyboard while typing. A keyboard Done action restores navigation.
- The Steps menu jumps to any section without pushing another editor onto the navigation stack.
- Opening a step moves accessibility focus to its heading.
- The last step is stored in UserDefaults, independently of the protected client draft. Navigating or skipping does not create answers, mark work complete, or change the upload payload.
- Existing drafts decode unchanged. Clearing the draft also resets the planner to step 1.
- Saving on exit retains the existing failure notice and keeps the planner open if changes could not be saved.
- The inspiration picker includes saved favorites first; selecting a project adds it to the existing shared brief.
- Web links are added in a dedicated sheet. Invalid URLs remain in the sheet with an inline correction message; an unfinished entry cannot be discarded by swiping the sheet away.
- Review offers an Edit control for every section. Return to review avoids retracing the remaining steps.
- Send to LINART is the primary final action. Empty or whitespace-only drafts cannot proceed from review. The existing sign-in, consent and submission screen still performs the actual send.
- PDF export is retained behind an expandable alternative. Save for later returns to My Project without submitting.

## Scope

Seven Swift files changed: the draft model, shared Studio store, three planning views, existing reliability tests and existing UI tests. The backend, authentication implementation, inquiry endpoint, Xcode project membership, signing, release settings and artwork are unchanged. No app build, live submission or deployment was initiated.

## Verification

Performed in the provided Linux workspace:

- Parsed all seven changed Swift files with the Swift tree-sitter grammar.
- Verified the Xcode object graph, source/resource membership, JSON/plist/XML files, catalog assets, privacy manifest, and regenerated SHA-256 manifest using Scripts/verify_package.py.
- Verified the final ZIP CRC, path safety, file list and byte-for-byte parity against the revised source.

Added/updated native regression coverage, **not executed here**:

- Resume a saved step after recreating the store without altering the brief or upload data.
- Clear the draft and navigation position together.
- Skip every optional step without inventing answers or a saved submission.
- Add a link, move Back/Continue, edit from review, save for later, relaunch and resume.
- Prevent sending an empty brief.
- Check large accessibility text, landscape review, existing inquiry validation and reset.

Run the existing iPhone and iPad validation workflows with Xcode before releasing this revision. Static parsing does not establish Apple compiler type correctness or on-device layout. Native photo import, VoiceOver, keyboard/rotation behavior, share sheets and the sign-in/send handoff still need simulator or device verification.
