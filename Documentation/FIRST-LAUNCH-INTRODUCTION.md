# LINART first-launch introduction

## Experience

A warm ivory introduction uses the bundled `kitchen-remodeling` photograph, a native serif LINART wordmark, restrained brass rules, and the approved copy: “Crafted around you” and “Your home. Beautifully reimagined.” No generated project imagery is shipped. The system launch background now matches the introduction's ivory.

The wordmark fades in and the photo gently settles over 0.8 seconds. After three uninterrupted seconds in the foreground, the screen crossfades into Home over 0.4 seconds. Skip is available immediately with a minimum 44-point target. Reduce Motion removes the reveal and dismissal animations. VoiceOver and accessibility text sizes use a persistent Continue button instead of timed dismissal.

Text is rendered natively and wraps; only the photograph crops. Portrait uses a vertical editorial composition. Landscape uses a split composition when space allows, with a scrollable text panel. Large accessibility text uses the scrollable vertical layout. The bottom control stays outside the scrolling content and within safe areas.

## Persistence and lifecycle

- `linart.hasSeenBrandIntroduction` is stored through AppStorage in local preferences, and set only when the introduction finishes or is skipped.
- The key is deliberately not tied to an app version. Once completed, reopening, tab navigation, foregrounding and app updates do not replay it.
- Existing installations see it once when they first install this revision. New installations see it at first opening. Restoring backed-up app preferences can also restore completion.
- If the app closes before completion, the next launch still offers the introduction. Backgrounding cancels the timer; returning starts a fresh three seconds rather than dismissing unseen content.
- Clearing saved projects/Studio data does not reset the introduction flag. No existing draft, favorite, checklist or inquiry data is changed.
- Home stays mounted behind the introduction, with hit testing and accessibility hidden until dismissal. The photo is bundled; no network request, permission or additional dependency is required.

## Verification

Performed on Linux for this revision:

- All 16 Swift source files parsed with the tree-sitter Swift grammar without syntax errors. This is not SwiftUI type checking.
- Existing package verifier: Xcode source/resource membership and object references, shared scheme, assets, catalog, property lists, privacy manifest and refreshed SHA-256 manifest.
- Whitespace/diff check and source review of completion persistence, cancellation, accessibility and the immediate Skip path.

Xcode compilation, XCTest, simulator rendering and physical-device visual verification remain outstanding. No Codemagic build or Apple upload was started for this change.

## On-device acceptance

1. On a fresh simulator install, verify the ivory introduction, real photo and fully visible text; let it finish, then force-close and reopen. It should open directly to Home.
2. On a separate fresh simulator install, tap Skip immediately, navigate through all tabs, and relaunch. It must not replay or leave an invisible touch-blocking layer.
3. Background during the introduction and return; confirm it provides a new reading interval. Close before completion and confirm it appears again.
4. Check a small iPhone, a large iPhone and iPad, portrait and landscape, offline, with the largest text sizes. Verify scrolling and the always-visible bottom control.
5. Enable Reduce Motion before launching: no zoom or fading. Enable VoiceOver or accessibility text: the screen waits for Continue, and Home controls cannot be reached behind it.
6. Upgrade an installation containing favorites and a Studio draft; verify the introduction appears once and the saved content remains intact.

Use a simulator reset or a dedicated test installation for repeat checks; do not delete an installation containing unsaved customer work just to replay the introduction.
