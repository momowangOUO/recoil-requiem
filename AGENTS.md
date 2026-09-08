# Recoil Requiem project guidance

- Read `docs/ART_STANDARD.md` before creating or changing character, environment, weapon, FX or UI art. It defines this project's pixel-art contract and rig/animation breakdown.
- The user has revised the original no-jump prototype: Space now jumps and combines with recoil. W remains air correction. See `docs/jump-update.md`.
- Use imagegen for authored character body artwork. Keep source assets and provenance inside the project; do not replace accepted sprites with geometric placeholder bodies.
- Keep the 320×180 internal resolution, integer scaling and nearest sampling. Inspect final art in the actual game at native pixel density.
- New body actions must respect the shared scale, per-frame translation anchors and independent aiming arms/gun layers in `PlayerVisual`.
- Reload feedback must use actual `WeaponRuntime.progress()`, including each shotgun shell, cancellation and pause behavior.
- Run `tools/run_checks.ps1` for gameplay changes. Relevant rendered fixtures are documented in README; record visual limitations honestly.
