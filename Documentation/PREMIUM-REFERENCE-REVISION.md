# LINART app reference revision — 2026-09-24

Base: `76abae746b008d550463a70f6d1616a7424f9cc4` in `joshmas90/linartinc-app`.

## Problem and design

The supplied iPhone recordings showed a cropped desktop website banner in Home, with text and fake button imagery embedded in the photograph. The app also had four tabs and a long Studio form instead of the supplied reference's five-tab, photo-led design.

This revision uses LINART's existing project photography and New Jersey business content with the reference's ivory surfaces, brass actions, serif headings, compact image cards and quieter borders. It does not invent project counts, completed work, service offerings, testimonials, automatic emails or backend capabilities.

## Changes

- Home: clean bundled kitchen photo, native wordmark, wrapping headline and body, working View Our Work button. The photograph alone is cropped. Text determines content height inside a scroll view, with a minimum hero height based on the available viewport. Safe areas remain managed by SwiftUI.
- Navigation: Home, Projects, Services, My Project, More. Existing tab identifiers for Projects and My Project are preserved so existing actions keep their destinations. Native iOS tab appearance varies by OS version; this is not a pixel copy of the illustrated phone frames.
- Projects: All / Kitchens / Bathrooms / Additions / Outdoor Living filters combine with search and saved-only filtering. Real photo counts, image-overlay cards, swipeable inline gallery, fullscreen gallery, favorite and inquiry actions.
- Services: dedicated thumbnail list, image-first detail pages, brass checkmarks and quote action. Related-project links appear only when the catalog contains matching work.
- My Project: Checklist and Saved Ideas segments; stored checklist/favorites keys are unchanged.
- Studio: menu linking to Your Space, Inspiration Photos, Inspiration Links, Project Details, Budget & Timing, Review & Share. Each editor loads and autosaves the existing draft format. Existing photo limits, optional prompts and manual PDF sharing remain.
- Inquiry: persistent field labels, refined form introduction and confirmation screen. Confirmed success can open the Studio directly. Existing validation, consent, endpoint, timeouts and error handling are preserved.
- More: brand portrait, About, Contact, Service Areas, sharing, Privacy and Settings. Settings reports file-deletion failures instead of silently claiming success.

## Verification performed

- Inspected the reference image, six frames from each supplied screen recording, existing hero asset and candidate project photos.
- Parsed all 15 app/test Swift source files with the tree-sitter Swift grammar: no syntax errors. This does not type-check SwiftUI or replace an Xcode build.
- Ran the existing package verifier: Xcode object graph, source/resource membership, scheme, catalog, image references, plist/privacy data and refreshed SHA-256 manifest.
- Reviewed changed navigation destinations, preserved tab identifiers, catalog-derived filters, form submission logic and local Studio persistence paths.
- `git diff --check` passed.

## Required device verification

No Xcode SDK or iOS simulator is available in this Linux environment. No Xcode compilation, XCTest execution, simulator screenshot, Codemagic build, TestFlight upload or App Store submission was performed for this revision.

Before distributing, run the existing manual unsigned Codemagic validation workflow, then inspect a build on a small iPhone, a current large iPhone and iPad. Check portrait/landscape, large accessibility text, the full hero headline and CTA, all five tabs, gallery paging/favorites, category + search combinations, keyboard/form errors, success-to-Studio routing, and Studio draft/photo persistence when returning between sections. Sending real inquiries remains a separate live check; no customer inquiry was submitted during this work.

The Studio still exports a client-shared PDF. It does not automatically upload or associate its notes/photos with the original inquiry; that backend work is separate.
