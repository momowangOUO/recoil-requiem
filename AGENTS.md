# Recoil Requiem project guidance

- Start project work with `dev-design/README.md` and `dev-design/DEVELOPMENT_RULES.md`, then only the relevant indexed documents. `dev-design/IMPLEMENTATION.md` separates completed work, pending narrative review and unimplemented gameplay. User cancelled the 80% quota stop on 2026-09-14.
- Story, character cards, motivation, relationship, narrative quest and dialogue work must read `tools/skills/game-story-workflow/SKILL.md` (also installed as `$game-story-workflow`) before drafting. Actually read its required existing skills and relevant templates; names alone are not invocation evidence. Do not route pure technical work through narrative skills. New story drafts are not canon until reviewed; revoked heart-replacement and corpse-auction premises must not return. Preserve the protagonist's existing name and all first-meeting relationships.

- Latest hand rig: SMG uses smg_left_support_v5.png with palm facing viewer. Keep support_palm_front's body/near-hand occlusion mask; never repaint the entire far hand unconditionally above the torso. Validate complete 360-degree aiming via tests/test_arm_rig.gd and tests/capture_aim_sweep.gd. See assets/characters/requiem/SMG_SUPPORT_V5.md.

- Current body artwork: player v5 sleeveless Gothic/steampunk vampire torso, Aegis v3, riflewoman v1. Use `requiem_*_v5_socket.png` with independently authored right-trigger and left-support parts. Bodies must have no sleeves; complete sleeves belong to upper arms. Fix shoulders to the torso, rotate upper/forearm around authored joints, and keep hand/gun registration. Never rotate the entire sleeved arm around the gun or duplicate a right hand as a left hand. Fit artwork on the whole character before splitting. See `assets/characters/requiem/GOTHIC_RIG_SOURCE.md` and `docs/screenshots/gothic_rig.png`.
- Main gameplay now uses `scenes/rooms/monastery_campaign.tscn`: 12000×2400 logical pixels, 16 spaces, three tiers. Preserve continuous coordinates and two-way traversal. `connected_monastery.tscn` and the five former rooms are legacy regression fixtures; do not restore their withdrawn story to the main game.
- Rooms are authored in `scenes/rooms/*.tscn` using PaperPlatform and RoomMarker; use the bundled Recoil Map editor and `docs/MAP_EDITOR.md`. New room gameplay and 3D geometry must share this data.
- User override (2026-09-14): the 80% remaining-quota stopping rule is cancelled. Do not stop work at that threshold. Account usage is not a per-task token count.

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

- User override (2026-09-14): protagonist name is 莉芙 (two syllables); keep the accepted white-haired, red-eyed player v5 artwork unchanged. This is a name change, not permission to redesign her appearance.
