# UI v2 imagegen source and integration record

All seven source sheets in `source/` were produced for this project with the built-in image generation tool on 2026-09-20. `tools/design/split_ui_v2.py` deterministically crops the runtime components; `SPLIT_MANIFEST.json` records each source rectangle and output size. Runtime text, values, quest state, fog, and reload progress are drawn by Godot, not baked into these images.

| Source | Generation direction | Runtime use |
|---|---|---|
| `ui_styleboard_v1.png` | A complete restrained Gothic/steampunk vampire-game UI screen, old silver, deep oxblood, ivory, carved accents outside quiet text zones; clear native-resolution type placeholders. | Visual target only, never rendered as a whole screen. |
| `ui_panels_v1.png` | Isolated transparent journal, tracker, dialogue, and five button-state frames; ornate corners, low-detail inner surfaces, generous text insets, no lettering. | Nine-slice panels and buttons. |
| `ui_combat_v1.png` | Isolated six-slot weapon emblems, health gems, revolver/shotgun/SMG silhouettes, reticle, and metal dial details in one matched atlas; transparent background, no text. | HUD, reticle, ring track, weapon icons. |
| `ui_map_concept_v1.png` | Top-down architectural parchment concept of a multi-height Gothic monastery with gatehouse, court, garden, archive, bellworks, chapel, and machinery; no labels. | Parchment texture only. Its speculative passages are **not** shown as accessible routes. |
| `ui_map_landmarks_v1.png` | Seven separate top-down architectural symbols in the same engraved map language, no connecting paths or text, transparent background. | Landmark symbols positioned by actual level coordinates. |
| `ui_map_marks_v1.png` | Isolated player, checkpoint, locked/open door, unknown, selection, route and blocked-route marks, no text, transparent background. | Data-driven map overlay. |
| `ui_reload_wedge_v1.png` | “Create ONE isolated UI asset for a gothic steampunk vampire action game: a single short curved metal inlay segment intended to repeat 24 times around a circular ammunition/reload dial. Pixel-art informed, high fidelity polished game UI, tarnished old silver outer bevel, quiet dark wine enamel center, slight ivory specular edge, luminous interior that can be tinted by engine from red through amber to teal. Symmetrical radial wedge/short arc segment, narrow width relative to length, clean silhouette, absolutely no neighboring segments, no ring, no border, no words, no numbers, no icons, no guns, no scene. Transparent background, alpha preserved, fully isolated with generous padding. Shape should read at 20x24 pixels when downscaled. One object only centered on canvas.” | One radial progress segment, tinted by live progress. |

The large sheets remain editable production sources. Runtime crops have alpha; the visual UI uses linear texture sampling at native UI resolution, while world/character pixels retain their separate nearest-neighbour settings. The map's navigable lines are exported from `dev-design/levels/image-led/as-built.json` by `tools/design/export_ui_map_geometry.py` into `data/campaign/monastery_map_ui.json`; imagegen never decides a traversable route.

Verification screenshots belong in `artifacts/` and are not source art. Re-run both extraction scripts after changing a source or level geometry.
