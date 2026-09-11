2026-09-11 覆盖说明：SMG 支撑臂与前掌遮挡已升级，运行时使用 smg_left_support_v5.png。下方原始绘制顺序属于历史记录，当前规则及 360° 验证见 [SMG_SUPPORT_V5.md](SMG_SUPPORT_V5.md)。

# 哥特主角与持枪拆件来源

制作日期：2026-09-10。使用内置 imagegen；工具没有可选择的模型版本，不能宣称指定使用了“image2.5”。原始位图保存在本目录，运行时只使用最后的无袖身体和左右手拆件。

## 源图和用途

| 文件 | 用途 |
|---|---|
| `requiem_idle_v4_gothic.png` / `requiem_run_v4_gothic.png` | 哥特服装设计源图：领巾、红宝石、束腰、黄铜扣件、燕尾衣摆；非最终身体层 |
| `held_body_fitting_v2.png` | 三枪完整人物试装；左轮已改成单手，长枪保留双手 |
| `held_arms_v2_fitted.png` | 从试装姿势提取的部件参考，保留作左右手校正的输入 |
| `held_arms_v3_handed.png` | 最终左右手源图；左列为右手扳机臂，右列为左手支撑/空闲臂 |
| `requiem_idle_v5_socket.png` / `requiem_run_v5_socket.png` | 最终身体层，无袖子、手臂和手掌，仅保留衣身袖窿 |
| `*_right_trigger_v3.png` | 右臂、握枪手与枪的裁区；运行时继续拆成上臂、前臂和手枪组合层 |
| `*_left_support_v3.png` | 独立左臂裁区；左轮自然垂手，霰弹掌心向上，SMG 四指包覆支撑位置 |

源图使用品红键底，并非已经透明的 PNG。`chroma_key.gdshader` 消除键底，角色采用最近邻采样。`tools/split_held_arms.py` 只做确定性裁切，并去掉 SMG 左手源图用于定位的多余握杆端部，不重画人物。

## 挂点和绘制

身体比例固定为 0.084，手臂源图比例固定为 0.05。两种源图的生成放大倍数不同，比例按实际人物校准；不会在旋转或换弹时改变。

身体坐标原点为脚底。近侧右肩为 `(-3 × facing, -26)`，远侧左肩为 `(1 × facing, -26)`。枪械瞄准点仍为 `(0,-26)`，真实枪口仍在方向前方 25 px。肩部位置固定，袖子只存在于上臂部件。

`PlayerVisual` 的 `RIGHT_*`、`LEFT_*` 分别记录源图肩、肘、腕与裁区。先根据真实手腕位置求肘点，再旋转作者绘制的上臂和前臂；不画线条手臂，不缩放骨段去凑距离。关节裁区留少量重叠，肘部用袖褶遮住接缝。所有正常瞄准与换弹目标均在两段手臂可达范围内，自动检查包含正上、正下和左右朝向。

绘制顺序：左上臂/前臂 → 无袖身体 → 右上臂/前臂 → 右手与枪 → 左手指尖。左手掌单独压在护木前，不能把右手复制过去。身体仅在袖窿处与上臂重叠，禁止再保留一份袖帽。瞄准时只转手腕/枪和骨段，身体保持直立。换弹的左手轨迹来自真实 `WeaponRuntime.progress()`。

## 生成提示词

最终左右手校正原文：

> Anatomical handedness correction to sprite atlas reference1, using full character reference2 for fitting. Preserve LEFT COLUMN exactly: these are the heroine's RIGHT firing arms, right index fingers operate triggers. Redraw ONLY RIGHT COLUMN as her anatomically distinct LEFT arms, NOT copies of the firing right hand. Keep right-column shoulder, elbow, wrist positions and overall short bent arm scale identical. Row1 LEFT free hand relaxed downward, seen from outside, thumb on the body-facing side, four relaxed fingers together. Row2 LEFT support hand supinated PALM UP to cradle shotgun fore-end; four fingers curl upward toward viewer and barrel, thumb on far side, mostly concealed behind barrel when assembled; no right-hand trigger-grip silhouette. Row3 LEFT support hand wraps vertical SMG foregrip, thumb lies on the far side, four curled fingers visible on near side; REMOVE the black magazine currently dangling below hand, no weapon part in support column. All arms use same burgundy sleeves, ivory cuffs, small brass buttons as ref2. No bare long forearms. Preserve exact six-cell layout, dimensions and anchors of ref1, magenta background, crisp pixel art. Distinct right trigger hand and left supporting hand; not two right hands. No text, no labels.

无袖身体清理原文（待机）：

> Precise production rig cleanup of this exact 2x2 pixel-art body atlas. Remove ALL burgundy puff sleeves and shoulder sleeve caps from ALL FOUR characters. Body artwork must contain ZERO sleeves, ZERO upper arms, ZERO forearms, ZERO hands. Only head, torso/clothing, waist, coat tails and legs. The burgundy waistcoat/jacket torso stops at its fitted sleeveless armhole, with a small dark recessed armhole opening at the natural shoulder where a separate sleeve will overlap. No hanging stump, no exposed flesh arm, no floating shoulder ball. Preserve the EXACT head, silver hair, face, red eyes, cravat ruby, corset, brass chain, coat tails, legs, boots, scale, positions and foot baselines. Do not redesign anything except removing the duplicated sleeves and completing the adjacent torso edge. Same 2x2 sheet dimensions, same pixel outlines and shading, pure magenta background. This torso will receive independently articulated complete sleeved arms, so no baked sleeve may remain.

运行与验收：`tests/capture_gothic.gd` 保存实际 GPU 画面；`tests/test_arm_rig.gd` 验证部件可达范围和固定长度。源图检查不代替游戏内检查。后续若要求手指逐帧装填或专门的持枪身体姿势，需要另作动作帧；本轮是作者绘制部件驱动的关节动画。
