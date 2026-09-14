# V claw asset and rig record

2026-09-14. Source artwork generated with the built-in imagegen tool. The existing accepted player body is not replaced.

## Source and fitting

- `claw_fitting_preview_v1.png`: original generated whole-character fitting preview, independent right claw hand and three claw streaks. Its checkerboard was baked into RGB and is not transparency; do not use it as a runtime sprite.
- `claw_fitting_source_v1.png`: second imagegen pass replacing the checkerboard with magenta. Runtime samples only the independent hand and streak regions; the full-body preview on the left is reference only and is never rendered. The existing `chroma_key.gdshader` removes the key color.
- Reference: `docs/screenshots/gothic_rig.png`, accepted player/enemy proportions and colors. The generated full-body fitting was inspected before selecting the standalone regions. The actual final fit is checked again on the accepted v5 body in `artifacts/claw/`.
- The source retains its full 1536×1024 image. Region drawing avoids destructive image editing or repainting the approved torso. Texture import is lossless, mipmaps disabled; `PlayerVisual` uses nearest sampling.

Hand source region: `(1000,125,340,270)`, shown at 12.6×10 logical pixels with wrist offset `(-0.5,-4.7)`. It is the near/right hand with fingertips forward and thumb below; it is never reused as the left hand. The existing independently authored left support arm rests at the waist. Right shoulder remains `(-3*facing,-26)`; old authored upper/forearm joints retain their lengths. Wrist forward travel tops out at 6.5 logical pixels. The gun and its gripping hand are stowed during the attack, then the normal full aiming rig returns. The SMG palm-front occlusion layer is skipped only during melee.

Scratch source region: `(900,425,565,545)`, shown at 25×27 logical pixels. Streaks appear during the hit period and fade through the first 0.07 seconds of recovery. Existing enemy `receive_hit` dispatch supplies hit flash, stun and world impact feedback.

## Generation prompts

First pass (reference image is style/proportion only):

> Create a production pixel-art sprite asset sheet on a genuinely transparent background for Recoil Requiem. Reference is style/proportion only; do not redraw or replace the existing accepted heroine. Sheet layout: LEFT HALF show a full-body side-view silver-haired adult vampire girl in the reference's red Gothic steampunk sleeveless bodice with separately sleeved arms, facing right, feet planted, her RIGHT near arm thrust forward ending in a pale open claw hand with four separated long sharp ivory fingernails and lower thumb, LEFT arm lowered keeping pistol at hip. This is a whole-character fitting preview only. RIGHT TOP QUARTER: the EXACT SAME right claw hand alone, wrist at left edge, fingers extending right, back of hand visible, four splayed pointed ivory nails, thumb below; no sleeve, no gun, no other body parts. RIGHT BOTTOM QUARTER: independent slashing FX: three parallel curved tapered ivory and blood-red claw streaks sweeping upper-left to bottom-right, no hand or body. Leave wide transparent margins separating all three assets. Low-resolution crisp pixel art, reference heroine ~42 logical pixels tall, hand ~10x9 logical pixels and scratch effect ~25x24 logical pixels; enlarged clean integer pixel blocks. Limited palette #151722 outline #E4BAA0 skin #BC8D81 shadow #FFF2BE nails #ED675D red FX. No HD painting, no soft edges, no text, no grid lines, no baked checkerboard, no weapon fused to claw hand. Clear anatomical hand and sharp nails.

Second pass (first generated image as edit target):

> Edit this asset sheet preserving exactly all existing character, hand and claw-streak shapes and positions. Replace EVERY background checkerboard pixel with perfectly uniform solid pure MAGENTA #ff00ff. No checkerboard remains, no grey patches, no floor or shadows. Preserve the black outlines of the sprites. The magenta background is intentional color-key for a game engine. Keep the whole-character fitting preview left, independent claw hand top right, scratch streak bottom right. Do not add any content. Crisp nearest-neighbor pixel edges.

## Visual scope

This is a readable first claw action using a new authored hand/effect and existing braced run-body frames, rather than a newly authored full-body melee animation set. Windup, sleeve articulation, sweep, short travel and recovery are present. It does not include a separate holstering animation or sound. The fitting preview body is not canon artwork. Generated imagery has no separately sourced third-party texture or logo; no additional license claim is made.

Validation: `tests/capture_claw_melee.gd` renders both facings on the production 3D stage, with native 640×360 world images and full-window images. This is engine-rendered scripted playback, not manual playtesting.
