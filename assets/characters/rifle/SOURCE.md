# 钟楼女枪手素材来源

2026-09-10，内置 `image_gen` 生成。运行时加载本目录 PNG，并使用项目 `chroma_key.gdshader` 去除品红底。PNG 原图保留，无程序绘制的人体或关节拼接。

| 文件 | 生成输出 ID | 用途 |
|---|---|---|
| rifle_shoot_v1.png | exec-6cfeb7d1-1888-4820-976f-58178dd1fcb7 | 守备、瞄准、射击回缩、装填四格 |
| rifle_death_v1.png | exec-45e19691-a318-4a86-b810-d1f51eb0645c | 屈膝、跪倒、侧倒、稳定倒地四格 |
| rifle_idle_v1.png | exec-4432c4d2-2cd4-4c5a-8106-8ce3477578c8 | 呼吸、肩部轻动、眨眼与回正四格 |

共同缩放 0.09，帧锚点见 RifleVisual.ROOTS。不得逐帧拉伸。射手不走路；受击仅闪白，尚未制作独立受击帧。最初 `exec-eca18a36-cc14-4c42-b62d-6498617c91cb` 生成了不透明棋盘底，未接入游戏；随后用 imagegen 改为品红键底。

## 初始射击图提示词

Generate game sprite sheet, using screenshot ONLY for character pixel style/proportions reference. New enemy: recognizable beautiful ADULT anime woman, copper bob hair, visible face, small ivory hair clasp, dark navy gothic longcoat with cream shoulder cape, charcoal trousers and flat boots. A sentry holding a long dark rifle with both hands. Low resolution pixel art same style as screenshot characters: large 12px head relative to 44px body, clear dark outline, 3-tone shading, readable pixel clusters. Authored WHOLE BODY shooting animation 4 frames in strict equal 2 by 2 grid on transparent background. All face RIGHT in side view and same camera same scale; boots at same baseline and pelvis same cell x. Frame1 relaxed guard rifle lowered slightly; frame2 rifle shouldered leaning forward aiming; frame3 rifle firing recoil shoulder and knees absorb kick NO baked muzzle flash; frame4 reloading rifle lowered, one hand at breech. Exactly one woman per cell, full intact anatomy, rifle attached to hands. No text, no grid lines, no background scene, no cast shadows, no checkerboard. Keep generous empty margins in each cell, identical body height approximately 420 source pixels in each 512px cell. Pixel clusters approx 8 source pixels, not painterly detail.

参考：实际游戏 `artifacts/stage3d_combat.png`。

## 修正键底提示词

Edit this exact 2x2 sprite sheet: replace ALL background including checkerboard, pale marks and shadows with completely flat SOLID MAGENTA #ff00ff. No transparent background, no checkerboard. Preserve the 4 women, all poses, pixel art, proportions, clothing, faces and weapons unchanged. Same grid and image dimensions. Every non-character pixel is pure magenta.

## 倒地提示词

Generate a separate DEATH ANIMATION sprite sheet for EXACT SAME adult copper-haired anime riflewoman in reference. Same low resolution pixel clusters and outline, identical head size and body scale, same navy cream clothes and rifle, no redesign. Strict 2x2 equal cells. FULL BODY authored poses facing right: top-left knees buckle, torso slumps, rifle lowered; top-right falls to one knee supporting herself with hand; bottom-left falls onto her side, legs bend, rifle drops beside hand; bottom-right lying motionless on side, face visible and boots naturally resting. Not gruesome, no blood. Each pose same physical scale as original standing 470px body per ~635px-wide cell, do not enlarge short/collapsed poses. Keep feet/ground baseline approx cell y560, center pelvis x310. Entire figure and rifle within each cell. Completely flat SOLID MAGENTA #ff00ff background throughout, NO transparency NO checkerboard NO text NO gridlines NO shadows.

参考：rifle_shoot_v1.png。

## 待机提示词

Create a separate four-frame IDLE BREATHING animation sheet of EXACT SAME adult anime copper-haired riflewoman, in same pixel art style, scale and proportions as the reference. 2x2 equal grid with one full-body figure per cell, all facing RIGHT. Use reference TOP-LEFT relaxed ready pose with rifle lowered diagonally held firmly by both hands in every frame. Very subtle authored changes only: frame1 neutral, frame2 shoulders inhale slightly (feet/pelvis unmoving), frame3 blink and cape moves gently, frame4 breathe out with slight rifle settling, loops back to frame1. Keep full source character height about 470px and same approximately 635x619 cells, consistent feet y560 and pelvis x285. No weapon independent floating, same hair and costume, natural arms. Pure solid #ff00ff magenta background. No checkerboard, transparency, grid lines, text, muzzle flash or extra objects. Crisp pixel clusters of 6-8 source pixels, flat 2-3 tone shading.

参考：rifle_shoot_v1.png。
