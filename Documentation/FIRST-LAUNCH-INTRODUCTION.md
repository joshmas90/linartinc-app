# LINART app-launch introduction

## Experience

A warm ivory introduction uses the dedicated `welcome-bathroom` artwork, a native serif LINART wordmark, restrained brass rules, and the approved copy: “Crafted around you” and “Your home. Beautifully reimagined.” The owner requested this AI-generated concept based on six supplied bathroom reference photos, followed by a neutral-white-balance and fixture-detail refinement. It is decorative splash artwork, not a documented portfolio project. See `SPLASH-ARTWORK.md` for provenance and the final edit prompt. The system launch background matches the introduction's ivory.

Five effects share one restrained sequence:

| Effect | Timing from appearance |
| --- | --- |
| Staggered typography | LINART: 0–0.55 s; tagline: 0.18–0.73 s; headline: 1.45–2.00 s; location: 1.70–2.15 s |
| Architectural reveal | Brass rule draws from its center at 0.28–0.73 s; a broad feathered photo reveal travels downward at 0.25–1.45 s |
| Cinematic photograph | Slow pullback from 1.055 to 1.000 scale at 0.25–2.20 s, with a three-point soft-focus/opacity transition resolving at 1.25 s |
| Brass light sweep | One masked highlight crosses only the LINART letters at 0.90–1.95 s |
| Entrance into the app | The finished composition holds still at 2.20–3.00 s, then dissolves into the mounted app at 3.00–3.65 s |

Skip is available immediately with a minimum 44-point target and also uses the short dissolve. Reduce Motion removes all animation. VoiceOver and accessibility text sizes show the complete static content and a Continue button instead of timed dismissal.

The photo entrance uses a broad alpha feather. A restrained focus transition and eased camera pullback let the room resolve gradually. The feather completes before the headline begins appearing; the final artwork is sharp, opaque and stationary for about 0.8 seconds before dismissal. The final scale is 1.0 so the complete composition is visible during the hold.

Text is rendered natively and wraps. The artwork stays in a square frame with ivory margins, up to 560 points across. Portrait reserves room for the wordmark and message on smaller phones; landscape uses a split composition with a scrollable text panel. Only the gentle opening zoom trims the image edges. Large accessibility text uses the scrollable vertical layout. The bottom control stays outside the scrolling content and within safe areas. Home retains its separate kitchen photograph, and portfolio/catalog imagery is unchanged.

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
4. Check a small iPhone, a large iPhone and iPad, portrait and landscape, offline, with the largest text sizes. Verify the complete square artwork, the still hold before dismissal, scrolling and the always-visible bottom control.
5. Enable Reduce Motion before launching: no zoom or fading. Enable VoiceOver or accessibility text: the screen waits for Continue, and Home controls cannot be reached behind it.
6. Use More → Settings → Replay welcome repeatedly, including immediately after Skip. Confirm the whole sequence restarts, and no old timer dismisses a newer replay.
7. Upgrade an installation containing favorites and a Studio draft; verify saved content remains intact. The old first-install completion flag must not suppress the welcome.

Earlier interactive conversation previews use the previous photograph and timing; they are not recordings of the native iPhone app. The current implementation and timing table above describe this revision. Codemagic remains manual.
