# Campaign enemy implementation and art record

2026-09-14. Six archetypes are implemented in `scripts/combat/campaign_enemy.gd`, extending `ShieldEnemy` and preserving the existing player target, hurtbox, weakpoint, `receive_hit`, `hit_received` and `defeated` interfaces. No narrative death flag or dialogue text is set here. The elite's collapsed combat pose can be hidden by the session when her encounter ends.

| Archetype | HP / mass | Actual behavior |
| --- | --- | --- |
| charger | 78 / 1.0 | Approaches, commits to a 0.45-second warning, rushes for 0.22 seconds, recovers for 0.6 seconds. One swept contact hit per attack. |
| grenadier | 66 / 1.0 | Locks a ground location during a 0.65-second windup, throws on a visible 0.6-second arc, leaves 0.5 seconds on the ground, then explodes once. Walls intercept the flight and block blast damage. |
| flyer | 60 / 1.0 | Approaches a hovering position, warns for 0.5 seconds, follows one locked straight swoop for 0.38 seconds, then lands into a 1-second vulnerable recovery. |
| support | 70 / 1.0 | Telegraphs then channels a visible connection to a nearby damaged ally. Heals at most 6 per pulse and 36 for its lifetime. Hits interrupt the connection; no revival. |
| elite | 140 / 1.35 | Alternates horizontal repositioning, then exposes a 0.4-second locked shot warning and shoots once. |
| boss | 240 / 2.0 | Repositions and aims in phase one. At half health enters recovery, then alternates committed horizontal rushes and locked shots in phase two. |

All use actual collision movement and world-wall queries. Ordinary base damage has no inherited shield armor: body ×1, back ×1.5, exposed recovery weakpoint ×2. Knockback divides by mass and accepted hits use the existing stun guard. Every damaging action is committed once rather than applied every frame. Dead actors remove body and weakpoint collision and emit defeat once.

`PROCESS_MODE_DISABLED` immediately cancels old hazards, shot traces, support links and windups via `NOTIFICATION_DISABLED`. Normal pause freezes simulation. Missing/dead targets or target distance above 700 also cancel hazards. The session controls the six-active-enemy budget; this class does not activate other enemies. All new actors join `campaign_enemies`; existing ShieldEnemy/RifleEnemy actors can join the same group for support healing. Optional `campaign_max_health` metadata overrides heal cap; old rifle and shield defaults are 72/120.

## Artwork

Each `*_actions_v1.png` is an independently generated complete eight-pose sheet. The first complete sheet was inspected before runtime region selection. No limbs from unrelated images are recombined; weapons stay in their authored whole-body poses. Each source uses an opaque magenta key, removed by the existing chroma-key shader. Lossless texture import, nearest sampling, no mipmaps.

Frame order: neutral / locomotion A / locomotion B / windup / attack / recovery / hurt / collapsed. The collapsed pose follows the authored hurt and lowered recovery frames, then stays still. The combat `DEAD` enum denotes a defeated actor, not a separate story decision. Windup, attack, recovery and hit visuals read actual runtime state. Neutral standing currently uses one authored pose; dedicated breathing animation, additional locomotion in-between frames and unique sound effects are not delivered. Generated A/B stepping frames have modest differences and need further animation polish; the action poses themselves are distinct. Elite movement frame B stows the pistol, while the other held-gun frames retain it. This is the first complete behavior/art pass, not a claim of final animation polish.

All six characters have uncovered faces, adult female proportions, distinct weapon/role silhouettes, and the accepted game's 12-ish-pixel head on a 42–44-pixel standing body. The flyer baseline excludes the wing tips. `tools/art/prepare_campaign_enemy_manifest.gd` measures source rectangles inside reviewed per-pose windows and writes `manifest.json` plus `manifest_data.gd`. It never modifies the images. Hand-entered pelvis X anchors and measured floor anchors translate poses; a single scale is shared by every pose in each sheet. `manifest_data.gd` is used by the runtime so the exported game does not depend on raw JSON inclusion.

The source image may cross an ideal equal-width grid with a spear, saber or wing; `manifest` records the correct individual regions. Do not crop these sheets as strict equal cells. NPC reuse can draw frame zero with the same region/anchor and scale. Paths and complete generation prompts are in `PROMPTS.md`.

## Verification

`tests/test_campaign_enemy.gd` currently runs 104 checks, including all six cycles, warning timing, single-hit charge, nontracking delayed grenade, disabled hazard cleanup, airborne pursuit and recovery, interrupted finite healing, no revival, lateral elite motion, wall-blocked shot, real boss phase changes, offscreen safety, one defeat event and removal of hurtboxes. It also checks authored state-to-frame selection and shared-scale bounds for all 48 poses.

The behavior-only baseline failed all six attack-cycle checks before implementation (`artifacts/enemies-red.log`). The latest isolated result is `artifacts/enemies-final.log`: 104 checks, zero failures, Godot 4.7.2.

`tests/capture_campaign_enemies.gd` places every new actor with the accepted player on the production 3D platform, samples all eight source poses in both directions, and writes native 640×360 and selected full-window captures to `artifacts/campaign_enemies/`. Rendered fitting has been inspected for all six types. These are scripted real-engine renders, not manual gameplay testing. The first capture used the obsolete platform height during concurrent map replacement; the final captures use the production environment's spawn-floor height.

Official API reference checked against the 4.7 docs: [Node processing and disabled notifications](https://docs.godotengine.org/en/4.7/classes/class_node.html), [PhysicsDirectSpaceState2D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate2d.html). Actual logic is exercised by the installed 4.7.2 engine.
