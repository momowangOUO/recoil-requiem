# 主角 v3 精细度统一

2026-09-10，用户指出主角比新敌人粗糙。通过内置 image_gen 细化原主角身体，保留角色身份、四格布局和游戏中的固定缩放 0.084；瞄准手臂、枪和换弹继续由 PlayerVisual 独立绘制。v2 源文件仍保存，当前身体加载 v3。

`requiem_idle_v3.png`：exec-209a0a9f-6d33-4f93-a29d-b4246dc802a0。
`requiem_run_v3.png`：exec-4da3ed47-e79b-4e3a-931b-d06a1ffe55a4。

## 待机提示词

Edit IMAGE 1 protagonist sprite sheet, IMAGE 2 is PIXEL DENSITY AND SHADING reference only. Refine the silver-haired ADULT anime heroine in image1 to the same intermediate fine pixel art quality as image2: smaller crisp pixel clusters (about 6-8 source pixels instead of original ~14), clearer face and eyes, defined silver hair locks, jacket seams, boots and belt. Preserve heroine identity: short silver-white bob, dark crimson hair ribbon, wine-red split-tail short coat, black trousers, flat black boots. Preserve original 2x2 grid, every pose and exact head/body proportions, exact per-cell body height and ground positions and pelvis anchors, unchanged transparent-part silhouette. Body layer only, shoulders/sleeves end at upper arms exactly as original; NO forearms, hands or gun because separate aiming rig supplies them. No new equipment. Image1 remains same dimensions. Solid flat magenta #ff00ff background. No smoothing, blur, gradients, noise, fine illustration or new art style. Match image2 clean outlines and stepped 2-3 tone shading. Don't copy the riflewoman's clothes or weapon. Frame1-4 remain subtle idle poses on stable feet.

参考图 1：requiem_idle_v2.png；参考图 2：../rifle/rifle_shoot_v1.png。

## 跑动提示词

Refine IMAGE1 running animation sheet to EXACT SAME heroine identity, face, silver hair and finer pixel-art treatment as IMAGE2. Image1 defines required 4 distinct run-cycle poses and per-frame foot/pelvis locations; Image2 defines approved appearance. Keep image1 2x2 layout, unchanged scale and silhouette, correct alternating legs in all four original poses. Silver bob, red ribbon, red split coat, black trousers and flat combat boots, recognizable adult anime woman. Retain clearly different contact/passing poses not 4 standing women. Add coherent crisp smaller pixel clusters, 2-3 tone shading, eye detail, jacket folds and boot structure matching image2. Preserve same full body height 500 source px, exact original per-cell foot positions, no individual scaling. BODY layer only shoulders and sleeves; NO arms below upper sleeve, no forearms, no hands, no guns, independent game rig provides these. Replace all background with solid flat MAGENTA #ff00ff. No black background, transparency, checkerboard, text, gridlines, blur or photoreal shading.

参考图 1：requiem_run_v2.png；参考图 2：requiem_idle_v3.png。

## 检查

保留品红底原图，运行时色键；Nearest 采样，人物按 2× 合成。用 `tests/capture_gallery.gd` 生成同镜头主角、盾兵、女枪手对照，并检查武器挂点。主角升降仍复用跑动姿势，专用落地、受击身体帧未完成。

## 猩红眼睛修订

同日用户要求吸血鬼式的更红眼睛。内置 image_gen 分别定向编辑上述两张已细化图片，当前使用以下原图：
- requiem_idle_v3_red.png：exec-b63d2871-08f7-4b06-9f21-88f4bb48d63b。
- requiem_run_v3_red.png：exec-b461bd90-9569-439d-93e7-62abd1617f20。

两个编辑调用使用相同完整提示词，参考各自的 v3 原图：

Edit only the visible eye IRIS in all four frames: make it vivid saturated scarlet red #f32343 with dark crimson shading and a tiny bright pink-white specular pixel, like a vampire. Eye must remain recognizable, keep dark pupil and upper lashes; no large glow halo. Absolutely preserve all other pixels, character face shape, hair, clothes, frame positions, canvas dimensions, body poses and flat magenta background. Do not recolor skin or outfit. This is a surgical pixel-art eye-color edit.
