# Recoil Requiem project guidance

- Every enemy, including elites and bosses, must be a recognizable adult anime beautiful girl with a visible face. Never substitute a faceless helmeted knight. Read `docs/ENEMY_ART_ANIMATION_STANDARD.md` before enemy work.
- Enemy animation must use articulated parts or authored animation frames: independent limbs, held shield/weapon, readable windup/attack/recovery/hurt/death. A translated static illustration is not an animation deliverable.
- Enemy art must match the accepted player sprite's pixel density, head/body proportions, outlines and shading. Verify player and enemy together in an in-game screenshot; a different detailed illustration style is not acceptable.
- Prefer authored whole-body action frames when cutout joints distort anatomy. Split only parts requiring independent control, and validate them first; never force a full-body IK rig from unrelated generated parts. Aegis v3 uses authored walk/bash/death grids, with fixed shared scale.

- Read `docs/ART_STANDARD.md` before creating or changing character, environment, weapon, FX or UI art. It defines this project's pixel-art contract and rig/animation breakdown.
- The user has revised the original no-jump prototype: Space now jumps and combines with recoil. W remains air correction. See `docs/jump-update.md`.
- Use imagegen for authored character body artwork. Keep source assets and provenance inside the project; do not replace accepted sprites with geometric placeholder bodies.
- Keep the 320×180 internal resolution, integer scaling and nearest sampling. Inspect final art in the actual game at native pixel density.
- New body actions must respect the shared scale, per-frame translation anchors and independent aiming arms/gun layers in `PlayerVisual`.
- Reload feedback must use actual `WeaponRuntime.progress()`, including each shotgun shell, cancellation and pause behavior.
- The arsenal has six fixed numbered slots. Slots 1-3 currently hold revolver, shotgun, and SMG; slots 4-6 are empty. Number keys select occupied slots directly; Q/wheel cycle all occupied slots and skip empty ones. There is no separate quick-slot model. All runtimes preserve ammo and cooldown.
- Run `tools/run_checks.ps1` for gameplay changes. Relevant rendered fixtures are documented in README; record visual limitations honestly.
