# LINART app-launch introduction

## Experience

A warm ivory introduction uses the bundled `kitchen-remodeling` photograph, a native serif LINART wordmark, restrained brass rules, and the approved copy: “Crafted around you” and “Your home. Beautifully reimagined.” No generated project imagery is shipped. The system launch background now matches the introduction's ivory.

Five effects share one restrained sequence:

| Effect | Timing from appearance |
| --- | --- |
| Staggered typography | LINART: 0–0.55 s; tagline: 0.18–0.73 s; headline: 0.85–1.45 s; location: 1.15–1.70 s |
| Architectural reveal | Brass rule draws from its center at 0.28–0.73 s; a broad feathered photo reveal travels downward at 0.35–1.80 s |
| Cinematic photograph | Slow pullback from 1.075 to 1.015 scale at 0.35–3.00 s, with a six-point soft-focus/opacity transition resolving at 1.60 s |
| Brass light sweep | One masked highlight crosses only the LINART letters at 0.90–1.95 s |
| Seamless entrance | Welcome dissolves into the mounted app at 3.00–3.65 s; the initial Home screen uses the same photograph |

Skip is available immediately with a minimum 44-point target and also uses the short dissolve. Reduce Motion removes all animation. VoiceOver and accessibility text sizes show the complete static content and a Continue button instead of timed dismissal.

The refined photo entrance uses a broad alpha feather rather than a hard mask edge. A restrained focus transition and eased camera pullback let the room resolve gradually; the final photograph is fully sharp and opaque before dismissal. The source photograph itself is unchanged.

Text is rendered natively and wraps; only the photograph crops. Portrait uses a vertical editorial composition. Landscape uses a split composition when space allows, with a scrollable text panel. Large accessibility text uses the scrollable vertical layout. The bottom control stays outside the scrolling content and within safe areas.

## Launch behavior

- The welcome appears on every fresh app launch, including after the user fully closes and reopens the app. The prior installation-wide completion preference is no longer read or written.
- Dismissal is kept in memory at the app root, outside the tab/navigation hierarchy. Page changes, tab changes, system dialogs and ordinary background/foreground transitions do not replay a completed welcome.
- If iOS terminates the process while it is in the background, the next opening is a fresh launch and shows the welcome. Suspended-process resumption does not.
- Backgrounding during an unfinished welcome cancels its dismissal timer. Returning gives a fresh reading interval for that same welcome; it does not restart the effects or create another screen.
- More → Settings → Replay welcome explicitly starts the sequence on Home without reinstalling or clearing data. It does not change the ordinary launch rule.
- The current screen stays mounted behind the introduction, with hit testing and accessibility hidden until dismissal. No draft, favorite, checklist or inquiry data is changed. The photo is bundled; no network request, permission or additional dependency is required.

## Verification

Performed on Linux for this revision:

- All 16 Swift source files parsed with the tree-sitter Swift grammar without syntax errors. This is not SwiftUI type checking.
- Existing package verifier: Xcode source/resource membership and object references, shared scheme, assets, catalog, property lists, privacy manifest and refreshed SHA-256 manifest.
- Whitespace/diff check and source review of per-launch state, cancellation, accessibility and the immediate Skip/replay paths.

Xcode compilation, XCTest, simulator rendering and physical-device visual verification remain outstanding. No Codemagic build or Apple upload was started for this change.

## On-device acceptance

1. Launch, let the welcome finish, fully close the app and relaunch. The sequence must play again without reinstalling or clearing preferences.
2. Tap Skip immediately, navigate through all tabs and nested pages, background the app and return. It must not replay a completed welcome or leave an invisible touch-blocking layer.
3. Background during an unfinished welcome and return; confirm it provides a fresh reading interval for the existing screen. Close the app fully and reopen to see a new sequence.
4. Check a small iPhone, a large iPhone and iPad, portrait and landscape, offline, with the largest text sizes. Verify scrolling and the always-visible bottom control.
5. Enable Reduce Motion before launching: no zoom or fading. Enable VoiceOver or accessibility text: the screen waits for Continue, and Home controls cannot be reached behind it.
6. Use More → Settings → Replay welcome repeatedly, including immediately after Skip. Confirm the whole sequence restarts, and no old timer dismisses a newer replay.
7. Upgrade an installation containing favorites and a Studio draft; verify saved content remains intact. The old first-install completion flag must not suppress the welcome.

The interactive conversation preview approximates the animation timing and composition; it is not a recording of the native iPhone app. Codemagic remains manual.
