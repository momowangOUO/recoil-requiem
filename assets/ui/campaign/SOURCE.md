# Campaign UI artwork

2026-09-14. Built-in imagegen; source retained unmodified as `campaign_atlas.png` (1536×1024). Runtime: `scripts/ui/campaign_ui.gd`. UI copy: `game-text/campaign-ui.md`. No text is baked into the generated atlas.

Prompt:

> Create a production-ready UI atlas for Gothic steampunk pixel-art vampire action game. Image 1536x1024, transparent background. NO TEXT, NO LETTERS, NO NUMBERS. Layout: upper half one complete wide shallow dialogue panel (roughly 1400x360) in worn deep wine-red leather, delicate antique silver corner ornaments, a few restrained ivory highlights, calm dark burgundy interior for clear runtime text. Lower-left one small quest tracker plaque (650x220) very subtle burgundy parchment and thin silver left flourish. Lower-right four small separate elegant monochrome ivory/silver icons: journal book, map compass, small lock, checkpoint candle. All components isolated with 50px padding, flat orthographic, clean sharp pixel-art clusters, no blurry painterly gradients, minimal decoration. Beautiful cohesive authored game UI, no giant black board, no world or characters, transparent exterior. Wide panel interior must be uniform quiet and usable behind 24px native Chinese text.

Generation returned an opaque atmospheric exterior despite the transparency request. We do not treat it as alpha. Production uses only rectangular panel regions fully inside the authored artwork; exterior background and unused icon cells are not drawn. Main panel region `(81,114,1372,376)` uses 32px nine-slice margins; tracker `(145,644,610,250)` is an AtlasTexture at 70% opacity. Splitting is non-destructive, through Godot region resources. Sampling is nearest. Generated icons are retained in source but not claimed as implemented.

The complete panel was fitted in a GPU-rendered UI fixture against the accepted game screenshot before the regions were finalized. Native text stays at 24px minimum on the 1280×720 canvas, scaling to 36px at 1920×1080. Plain native buttons provide interactive states over the authored panel. The panel occupies local screen space and does not alter the combat HUD.

Verification: Godot 4.7.2 stable, OpenGL/NVIDIA RTX 3070; `tests/test_campaign_ui.gd`. Captures: `docs/screenshots/campaign_dialogue_1280.png`, `campaign_journal_1280.png`, `campaign_map_1920.png`. Bounds, paused mouse choice, close signal and tracker persistence checked. These are GPU UI fixtures over an existing game screenshot, not a fresh complete-game playthrough; root integration supplies the final live-game acceptance check.

No third-party artwork was copied; generated assets carry no independent third-party license declaration. ResourceLoader is used after import for export compatibility; raw image fallback is only for pre-import development fixtures.
