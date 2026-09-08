# Requiem pixel body v2

Created with built-in imagegen on 2026-09-08 for this project. No external character artwork is used.

| Runtime asset | Generation source | Format |
|---|---|---|
| requiem_idle_v2.png | exec-d5483666-445e-4136-bd6f-e49dbc1f732e.png | 1268×1240, 2×2, magenta key source |
| requiem_run_v2.png | exec-cbf8f642-a245-40c2-9cee-27c24e084742.png | 1268×1240, 2×2, RGBA |

Original images remain in the local Codex generated_images folder. These workspace copies are the runtime source of truth. The earlier detailed concept illustrations and baked-checkerboard drafts are rejected and are not referenced by the project.

Both atlases show the same low-resolution silver-haired gothic heroine, burgundy coat, dark trousers and boots. Visible arms and weapons were excluded from the accepted body sheets. `PlayerVisual` draws the articulated aiming/reload arm rig and three weapon silhouettes separately.

All frames use a shared 0.084 world-pixels-per-source-pixel scale. Per-frame translations correct source placement only; no per-frame body resizing is used. Idle visible heights are 495–505 source pixels (41.6–42.4 world pixels); run heights are 492–503 (41.3–42.3). Horizontal anchors follow the stable hair/head cluster; vertical anchors use the boot baseline. `PlayerVisual` contains the measured frame anchors.

The image generator returned baked checkerboards when asked to remove the idle background. A subsequent imagegen edit replaced that background with magenta. The original RGB source is preserved; `chroma_key.gdshader` removes only the magenta key at draw time. The run sheet retains its generated alpha. This is a runtime transparency setup, not a claim that the idle PNG itself has a transparent alpha channel.

Idle uses four frames at 5 FPS, run four frames at 10 FPS. The current prototype reuses run frames 2 and 4 as ascent/descent poses. Dedicated jump, landing, hurt and detailed reload body sheets remain future art work; the current hand rig already responds to actual reload state.

See `docs/ART_STANDARD.md` for the project contract and `tests/capture_character_rig.gd` for a visual fixture of poses and hand/gun attachments.
