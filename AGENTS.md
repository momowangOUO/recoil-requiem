# Recoil Requiem project guidance

- Current body artwork: player v3 idle/run, Aegis v3, riflewoman v1. The user explicitly requested finer protagonist detail to match enemies; compare all three in `artifacts/character_lineup_v3.png`. Keep authored body sources and independent player aiming arms.
- Rooms are authored in `scenes/rooms/*.tscn` using PaperPlatform and RoomMarker; use the bundled Recoil Map editor and `docs/MAP_EDITOR.md`. New room gameplay and 3D geometry must share this data.
- During this work the user requested periodic account-usage checks, wrapping up with records and GitHub sync if remaining quota falls below 80%. Usage percentages are account limits, not exact token counts.

- Latest user override (2026-09-10): use real 3D scenery, perspective Camera3D and lighting with pixel-art paper characters; retain existing 2D gameplay physics. This overrides the attached v1.3 document's pure-2D presentation restriction. Main scene is `scenes/game.tscn`.
- Logical gameplay remains 320×180, but world rendering is now 640×360 and actor compositing is 2× to preserve artwork detail. UI renders on the native-resolution canvas. This user-requested quality upgrade overrides the older 320×180-only render rule below. Keep nearest sampling for game textures, clear native-resolution UI text, and no perspective scaling added to individual animation frames.
- Greybox must retain actual 3D platform depth, perspective and lighting. Old laboratories are internal regression fixtures, not player-facing destinations. Read `docs/VISUAL_IMPLEMENTATION.md` before changing the presentation pipeline.

- Every enemy, including elites and bosses, must be a recognizable adult anime beautiful girl with a visible face. Never substitute a faceless helmeted knight. Read `docs/ENEMY_ART_ANIMATION_STANDARD.md` before enemy work.
- Enemy animation must use articulated parts or authored animation frames: independent limbs, held shield/weapon, readable windup/attack/recovery/hurt/death. A translated static illustration is not an animation deliverable.
- Enemy art must match the accepted player sprite's pixel density, head/body proportions, outlines and shading. Verify player and enemy together in an in-game screenshot; a different detailed illustration style is not acceptable.
- Prefer authored whole-body action frames when cutout joints distort anatomy. Split only parts requiring independent control, and validate them first; never force a full-body IK rig from unrelated generated parts. Aegis v3 uses authored walk/bash/death grids, with fixed shared scale.

- Read `docs/ART_STANDARD.md` before creating or changing character, environment, weapon, FX or UI art. It defines this project's pixel-art contract and rig/animation breakdown.
- The user has revised the original no-jump prototype: Space now jumps and combines with recoil. W remains air correction. See `docs/jump-update.md`.
- Use imagegen for authored character body artwork. Keep source assets and provenance inside the project; do not replace accepted sprites with geometric placeholder bodies.
- Keep the 320×180 logical coordinates, integer window scaling and nearest world sampling; use the current render resolutions above. Inspect final art in the actual game at native pixel density.
- New body actions must respect the shared scale, per-frame translation anchors and independent aiming arms/gun layers in `PlayerVisual`.
- Reload feedback must use actual `WeaponRuntime.progress()`, including each shotgun shell, cancellation and pause behavior.
- The arsenal has six fixed numbered slots. Slots 1-3 currently hold revolver, shotgun, and SMG; slots 4-6 are empty. Number keys select occupied slots directly; Q/wheel cycle all occupied slots and skip empty ones. There is no separate quick-slot model. All runtimes preserve ammo and cooldown.
- Run `tools/run_checks.ps1` for gameplay changes. Relevant rendered fixtures are documented in README; record visual limitations honestly.

- Stone platforms block from all sides; only visibly open metal grating may use one-way collision. PaperPlatform defaults to solid. Check complete routes after changing platform collision, including headroom and leaving upper platforms.
- Keep exactly one Windows output: builds/windows/RecoilRequiem.exe. Update this filename instead of adding named variants.
- The user's natural-writing-zh skill was downloaded from GitHub. New player-visible prose must have a reviewed standalone game-text draft before integration; retain IDs and verify decoded target text against the draft.
