# Native UI pixel typography

User request (2026-09-21): all visible writing should have a mild pixel-art appearance while staying readable. The main game now bundles unmodified **GNU Unifont 18.0.01** (16-pixel authored glyph grid), covering Chinese, Latin text, digits and interface symbols with one font.

- Official source: https://unifoundry.com/unifont/index.html
- Download: https://unifoundry.com/pub/unifont/unifont-18.0.01/font-builds/unifont-18.0.01.otf
- SHA256: `88D0A14D4AA9A96419720B39BA5DA921A59560D76D4EC7D523ACC06ED85CD3C2`
- Redistribution uses the supplied SIL Open Font License 1.1. `OFL-Unifont.txt` retains its complete terms; `COPYRIGHT-Unifont.txt` preserves the font's embedded copyright, version and license notices. Both ship inside the executable pack.

Godot 4.7.2 uses this as the project GUI font and as the main scene's ThemeDB fallback for custom drawing. UI remains native-resolution; the glyph design supplies the pixel character rather than shrinking the whole interface. Subpixel positioning and system font fallback are disabled. Grayscale coverage softens fractional scaling without replacing the stepped glyph shapes. Do not add a smooth CJK system fallback, MSDF smoothing, a low-resolution UI viewport, or thick text outlines to fake this style.

Godot reference: https://docs.godotengine.org/en/4.7/classes/class_resourceimporterdynamicfont.html
