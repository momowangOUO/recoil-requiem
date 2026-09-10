# Aegis 盾兵造型

## 当前运行版本 v3（2026-09-09）

内置 imagegen 重新生成三组 2×2 完整人物动作图：aegis_walk_v3.png（四步行走）、aegis_bash_v3.png（防御、蓄力、前推、收招）、aegis_death_v3.png（踉跄、跪倒、倒下、卧地）。行走生成以 artifacts/replay_number_weapon_switch.png 中主角为画风参考，后续两组以已生成盾兵图锁定身份。核心提示：same beautiful adult lavender-haired female shield knight; match protagonist proportions and chunky pixels; complete connected bodies; exact 2x2; same anatomical scale; no detached limbs; pure magenta background; natural walking / continuous shield bash / non-graphic defeat.

ShieldVisual 统一 BODY_SCALE=0.09，透明裁切后只做脚底与骨盆平移对齐，不逐帧缩放、不拉伸肢体。正面盾臂与身体一起绘制完整姿态，使用真实攻击状态选择帧；死亡每 0.18 秒一帧并停在末帧。待机复用 bash 0，受击闪白。测试截图为 artifacts/enemy_0.png 至 enemy_4.png 及 enemy_walk_1/2.png。

v1、v2 因造型不符或肢体扭曲被用户否决，从未成为当前 v3 的制作母版。对应 PNG 已在 2026-09-10 的素材清理中删除，提示词与变更仍可从 Git 历史追溯。

## 已否决的 v2（2026-09-09）

该版曾尝试九格拆件，但肢体关系失真，未被 v3 运行时或后续生成采用。

画风基准为主角实机像素密度与头身比例。头部 14×15、躯干 16×20、盾 14×30 逻辑像素；四肢使用关节连接，左右共用生成纹理、后侧压暗。盾绕持握点转动。动作由 ShieldVisual 读取真实状态，待机、移动、蓄力、攻击、收招、受击、死亡分开控制。骨骼式动画，不宣称是独立生成的逐帧动画。

## 已否决的 v1

该版使用封闭头盔，遮挡美少女脸部、与主角画风不符，而且只有静态整图，因此已删除。

提示词：single full-body female gothic shield infantry knight, side view facing RIGHT, standing guard; low resolution pixel art, 48px tall character for a 320x180 game; limited charcoal, slate silver, muted purple and crimson palette; closed helmet, readable armored boots, tall silver kite shield attached to forearm; transparent background; no text, grid, arrows or environment.

当前代码不再包含该版的裁切或动画路径。
