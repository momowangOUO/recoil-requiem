# Aegis 盾兵造型

## 当前运行版本 v3（2026-09-09）

内置 imagegen 重新生成三组 2×2 完整人物动作图：aegis_walk_v3.png（四步行走）、aegis_bash_v3.png（防御、蓄力、前推、收招）、aegis_death_v3.png（踉跄、跪倒、倒下、卧地）。行走生成以 artifacts/replay_number_weapon_switch.png 中主角为画风参考，后续两组以已生成盾兵图锁定身份。核心提示：same beautiful adult lavender-haired female shield knight; match protagonist proportions and chunky pixels; complete connected bodies; exact 2x2; same anatomical scale; no detached limbs; pure magenta background; natural walking / continuous shield bash / non-graphic defeat.

ShieldVisual 统一 BODY_SCALE=0.09，透明裁切后只做脚底与骨盆平移对齐，不逐帧缩放、不拉伸肢体。正面盾臂与身体一起绘制完整姿态，使用真实攻击状态选择帧；死亡每 0.18 秒一帧并停在末帧。待机复用 bash 0，受击闪白。测试截图为 artifacts/enemy_0.png 至 enemy_4.png 及 enemy_walk_1/2.png。

v2 因扭曲已被用户否决，不再加载；以下为历史记录。

## 已否决的 v2（2026-09-09）

内置 imagegen 生成 aegis_parts_v2.png，九格拆件：头脸、躯干、上臂、前臂、大腿、小腿、盾、后发、备用肩甲。运行时只使用 v2。生成提示要求：adult anime beautiful female gothic shield knight, visible feminine face, lavender silver bob hair and violet eyes, no helmet; low-resolution pixel art, limited charcoal/silver/purple palette; exactly 3x3 isolated rig parts, no full figures, no labels, magenta key background.上臂格包含多余前臂，仅使用上段 48%。部件有效区域按 alpha>0.8 且非品红检测，缓存供各实例共享。

画风基准为主角实机像素密度与头身比例。头部 14×15、躯干 16×20、盾 14×30 逻辑像素；四肢使用关节连接，左右共用生成纹理、后侧压暗。盾绕持握点转动。动作由 ShieldVisual 读取真实状态，待机、移动、蓄力、攻击、收招、受击、死亡分开控制。骨骼式动画，不宣称是独立生成的逐帧动画。

## 已否决的 v1

下述封闭头盔图仅保留历史，不再加载。原因：遮挡美少女脸部、与主角画风不符、静态整图缺少拆件动作。

2026-09-09，使用内置 imagegen 生成，原图保存为 aegis_guard_source.png。

提示词：single full-body female gothic shield infantry knight, side view facing RIGHT, standing guard; low resolution pixel art, 48px tall character for a 320x180 game; limited charcoal, slate silver, muted purple and crimson palette; closed helmet, readable armored boots, tall silver kite shield attached to forearm; transparent background; no text, grid, arrows or environment.

运行时共享裁切区域 (384,76,516,1104)，绘制高度 48px，最近邻采样，脚底对齐。当前是单张生成姿态，蓄力后移、盾击前冲、收招下沉、死亡旋转由实际状态驱动；移动仅轻微起伏，不声称已完成逐帧行走动画。身体和盾目前烘焙在同一张图，独立手臂与盾牌动画列入正式关卡排期第一阶段的后续精修。
