# LINART splash artwork

The owner requested an ultra-premium splash-screen image inspired by six supplied bathroom photos, then approved a finishing pass and publication to main. The final asset is `LINART/Resources/Assets.xcassets/welcome-bathroom.imageset/welcome-bathroom.png` (1254 × 1254, opaque RGB PNG). Its hash is recorded in `AssetSources.json` and the package manifest.

This is an AI-generated marketing concept, not a photograph documenting a completed project. It is used only by the decorative welcome introduction. Home, service and project galleries retain their existing photos. No text or logo is baked into the image; LINART branding is native SwiftUI text.

All six supplied references were inspected: `IMG_0329.JPG`, `IMG_0325.JPG`, `IMG_0328.JPG`, `IMG_0327.JPG`, `IMG_0330.JPG`, and `IMG_0326.JPG`. The initial generation used the five complementary references (`IMG_0329`, `IMG_0328`, `IMG_0327`, `IMG_0330`, `IMG_0326`) as direct image inputs because the image tool accepts a maximum of five paths. Their shared design language supplied the white pedestal tub, traditional millwork, aged brick, marble, clear glass, nickel fittings and hexagonal stone floor. The resulting image was then used as the edit target for the finishing pass below.

Method: built-in imagegen for both generation and editing; no fallback CLI. The final output was copied unchanged into the asset catalog. The tool delivered 1254 × 1254 pixels despite the prompt's preferred 2048 × 2048 size. The app's settled frame is capped at 560 points, keeping the complete image within a 1120-pixel iPad Retina frame; ordinary iPhone frames are smaller.

## Final edit prompt

```text
Use case: precise-object-edit.
Asset type: finished luxury architectural photograph for the LINART mobile app splash screen.
Input image 1 is the EDIT TARGET. Perform a careful finishing retouch of this exact image, preserving its room, architecture, camera position, square framing, bathtub silhouette, window, aged brick chimney, lighting direction, shadows, niches, sparse styling, and overall composition. This is a subtle refinement, not a redesign.

Make only these two finishing changes:
1. White balance and tonal finish: reduce the yellow cast slightly, so the porcelain tub, painted millwork, and pale stone read as clean soft ivory under natural daylight. Retain the gentle afternoon warmth, warm brick, green garden, and dimensional shadows. Do not make it cold, blue, sterile, flat, desaturated, or dramatically brighter. Preserve delicate reflections and stone texture. Refined neutral whites with restrained warm highlights, sophisticated architectural editorial color grading.
2. Physically convincing fittings: replace the confusing bathtub faucet assembly with a beautifully made, simple traditional polished-nickel deck-mounted bridge bath mixer, correctly attached at the rear rim, with two matching cross handles, two clean mounting bases, and one central curved spout clearly extending forward over the inside of the tub. Remove the extra handheld shower wand, hose, and redundant attachments. Exact realistic construction, clean connected metalwork, correct scale and reflections, no floating or fused parts. Refine the far-right shower hardware into one coherent frameless hinged-glass door system: a single straight vertical polished-nickel pull and discreet logically placed hinges, no competing sliding track or duplicated mechanisms. Keep the shower's existing position, proportions, marble, clear glass, and reflections.

Preserve the original's expensive calm, natural material texture, straight architectural lines, finely detailed moldings, believable masonry, and understated styling. Keep the entire bathtub within the frame and retain all surrounding margin for the mobile splash screen's gentle 1.075x zoom. No added props, people, flowers, signage, branding, typography, borders, watermarks, phone frame, or UI. No fake blur, plastic rendering, excessive clarity, HDR halos, theatrical lighting, or heavy vignette.

Output one pristine high-resolution square 1:1 photograph, ideally 2048 by 2048 pixels. The finished result should feel like meticulous professional architectural photography.
```

The app's final zoom was reduced to 1.055 → 1.000, with a complete square frame at rest. Source images were visually inspected; native iPhone/iPad rendering still requires an Xcode build and device review.
