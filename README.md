# 反冲挽歌 · 猩红修道院

当前主入口为 `scenes/game.tscn`：真实 3D 场景、透视镜头与光影，搭配二维像素角色和既有二维战斗。场景以 640×360 渲染、人物两倍采样，UI 使用窗口原生分辨率。实现结构、用户对 v1.3 附件的覆盖及已知限制见 [视觉实现说明](docs/VISUAL_IMPLEMENTATION.md)。

正式关卡开发安排见 [序章开发排期](docs/LEVEL_ROADMAP.md)。盾兵 v3 采用与主角同风格的露脸美少女完整动作帧，已替换扭曲的 v2 拆件；行走、盾击和倒地共 12 帧。敌人统一画风与动作要求见 [敌人开发标准](docs/ENEMY_ART_ANIMATION_STANDARD.md)。运行 tests/capture_enemy.gd 可生成主角同屏与各动作检查图。

Godot 4.7.2 / GDScript / Windows 键鼠原型。三把枪分别提供单发修正、爆发位移和持续缓降；银盾祷姬支持绕背、弱点和击落。

用 Godot 4.7.2 打开 `project.godot`，按 **F5**，直接进入猩红修道院切片。Windows 独立文件为 `builds/windows/RecoilRequiem.exe`。无需插件或额外下载素材。角色和场景贴图源文件均保存在工程内，枪声在运行时合成。

当前包含东庭与钟楼外廊两段连续关卡，新增守点女枪手。清场走到东门自动前进，Backspace 重试当前房间。开发用地图编辑器集成在 Godot 的 Recoil Map 面板，支持放置平台与敌人、校验、保存和真实 3D 试玩。详见 [地图编辑器](docs/MAP_EDITOR.md) 与 [本轮开发记录](docs/BELL_GALLERY_DELIVERY.md)。

## 操作

| 按键 | 行为 |
|---|---|
| A / D | 左右移动，与瞄准独立 |
| Space | 地面跳跃，可与开枪反冲叠加；无空中二段跳 |
| W / S | 空中轻微修正；W 不起跳，S 可下穿青色单向平台 |
| 鼠标 / 左键 | 独立瞄准 / 射击；左轮和霰弹按次点击，SMG 按住连射 |
| 鼠标拖到屏幕边缘 | 平滑拉远视野；所有枪准星均可到达屏幕边缘；外侧 10% 鼠标区域提供画外瞄准，左轮/霰弹/SMG 上限为 32/8/20 逻辑像素；霰弹镜头最近 |
| R | 换弹；空弹自动装填，空中继续下坠 |
| Q / 滚轮 | 在所有非空枪槽间循环：1→2→3→1 |
| 1 / 2 / 3 | 直接切出左轮 / 霰弹枪 / SMG；各枪状态独立保留 |
| 4 / 5 / 6 | 预留武器位；当前版本按下不切枪 |
| F6 | 白模 / 贴图切换，保留相同的 3D 平台、镜头和光源 |
| Backspace | 重置当前房间 |
| Tab / Esc | 打开调参面板 / 暂停；再次按下恢复 |
| F11 | 切换全屏 |

Space 跳跃，向下开枪继续抬升；朝移动方向开枪刹车，反向开枪加速。支持 0.10 秒离台宽限和落地前输入缓冲，按住 Space 不会连续自动跳跃。地面枪械反冲会受到正常地面刹车影响，空中保留更多动量。枪槽固定为 1–6：当前版本 1–3 有枪，4–6 为空；Q/滚轮循环所有非空枪槽。

默认使用 **Responsive** 参数：跳跃高度约 50 px，落地比初版更快；地面有更强的刹车和水平反冲吸收，空中方向输入有 220 px/s 巡航上限，松手后逐渐减速。枪械反冲仍可突破巡航速度。Tab 底部 **GDD** 恢复旧参数，**Responsive** 恢复当前默认，两者均重置当前实验。调整详情和对照数据见 [docs/movement-feel.md](docs/movement-feel.md)。

准星周围的圆环显示真实换弹进度，随时间从红橙经过金黄变为青绿。霰弹每颗装填重新计一圈；HUD 同时显示换弹百分比、当前弹格、六格武器栏和五格生命。当前格为青色方括号，已有枪为亮色，空格以 `-` 标记。

## 试玩顺序

最新默认手感：水平反冲增加 10%；空中向下开枪首发保留真实冲量，后续缓慢衰减并保留 35%，向上速度限制为 1000 px/s，落地恢复。下坠时的射击制动仍然有效，重力数值不因射击改变。跳跃加霰弹不再将两份完整升力直接叠加。Movement 可调整 Horizontal kick 和 Air lift ceiling；GDD 保留历史对照。人物旁的测量箭头已移除。

1. 从左侧安全地面出发，Space 跳上第一落脚台，向下射击比较跳跃与反冲组合。观察镜头跟随时平台侧面、后方建筑和烛光的空间变化。
2. 经中央高台或上方路线接近盾兵，观察盾击预警，绕至侧后攻击；可以用霰弹把她打落至低层继续追击。用 S 下穿平台，SMG 向下射击控制下降，落地换弹。
3. 击败盾兵后前往最右侧亮起的门，出现房间完成提示。F6 检查白模是否保持相同的纵深，Backspace 重试，Tab 测试暂停与调参。

旧实验室不再是玩家入口，`scenes/lab.tscn` 仅供既有回归测试。当前是一间视觉切片，不是已经完成的正式序章。

## 调参规则

- Movement：重力、跳跃冲量（当前默认 440；GDD 为 460）、地面加减速、空中控制、方向输入巡航速度、空中松手减速、地面水平反冲比例、终端下落速度、速度软上限和超速阻尼。空中垂直修正最多为重力的 80%，防止 W 产生免费飞行。
- Weapons：分别调整三把枪的反冲、射速和换弹时间。霰弹的换弹时间是每颗弹壳的时间。
- Trial：固定靶/活动盾兵、转身速度、物理测量模式和震屏。测量模式关闭震屏；原型不使用全局停顿改变物理时间。
- Apply 会重置实验；GDD 恢复文档参数，Responsive 恢复当前默认。**修改仅保留在本次运行内，关闭游戏会丢弃调参结果。** 数据资源不会被面板写回。
- 三把枪始终各自保留弹量和射击冷却。数字键和 Q 使用相同的切枪规则：打断装填后切回原枪，会重新开始未完成的装填过程；已经装好的霰弹保留。选择当前枪不会取消正在进行的装填。当前版本的 4–6 格为空，按数字键时保持现有武器，Q/滚轮会跳过这些空格。
- 逻辑画布 320×180；世界采样 640×360，UI 独立高清绘制。窗口保持整数比例和最近邻世界采样；非匹配比例留黑边。

## 验证

在项目目录打开 PowerShell：

```powershell
./tools/run_checks.ps1
```

Godot 安装在其他位置时：

```powershell
./tools/run_checks.ps1 -Godot 'C:\Godot\Godot.exe'
```

检查会先导入项目，再分别在 30/60/144 渲染帧率、固定 60 Hz 物理步长下运行核心与集成检查，随后验证调参界面，并在 60 FPS 下运行键鼠事件回放。详细日志写入 `artifacts/`。测试失败返回非零退出码。

同一入口还会执行 `test_paper_stage.gd` 的真实弹丸击落测试及 `test_stage_3d.gd` 的透视投影、高清 UI 坐标、输入、暂停和重置验证。

当前生产场景实机截图：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://tests/capture_stage_3d.gd
```

输出 `artifacts/stage3d_entry.png`、`stage3d_combat.png`、`stage3d_greybox.png`、`stage3d_angle.png` 及对应世界原始采样图。下列旧实验室截图入口仅用于历史回归。

独立运行一次核心检查：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --fixed-fps 60 --script res://tests/run_tests.gd
```

运行三个场景及调参面板的渲染截图检查：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://tests/capture_scene.gd
```

运行带渲染截图的键鼠事件回放：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://tests/replay_playtest.gd
```

回放使用生产键鼠采集器、角色物理和投射物，注入引擎输入事件；不代表原生桌面输入或人工手感验收。该入口的计时要求 `--fixed-fps 60`。结果写入 `artifacts/replay_results.json`，无渲染版本写入 `replay_headless.json`。

截图也写入 `artifacts/`。本机验证结果及试玩方式见 `docs/playtest-report.md`。

检查人物动作分层、左右及上下持枪、换弹手部：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path . --fixed-fps 60 --script res://tests/capture_character_rig.gd
```

输出 `artifacts/character_rig.png`。事件回放还会输出普通跳跃、跳跃叠加反冲，以及换弹早/中/晚三个阶段的游戏截图。

## 实现结构

| 目录 | 职责 |
|---|---|
| `data/weapons/` | 三把枪的 GDD 基线 Resource |
| `scripts/core/` | 输入快照、物理参数、武器参数/运行状态、发射快照 |
| `scripts/player/` | 键鼠采集、CharacterBody2D 控制器、六格武器栏控制 |
| `scripts/combat/` | 扫掠投射物、盾兵状态机、方向性伤害 |
| `scripts/lab/` | 实验切换、场地、相机、音效与反馈 |
| `scripts/ui/` | 独立准星、HUD、暂停调参面板 |
| `tests/` | 无第三方依赖的 Godot 测试与渲染入口 |

`InputFrame` 可注入实际角色控制器；每次有效开火只发出一次 `shot_fired`。`ShotContext` 固定开火时的攻击来源，投射物每帧扫掠路径并只派发一次命中。霰弹的敌人击退总量在七颗弹丸之间分摊，弱点倍率覆盖正侧背倍率。

当前交付是反冲实验室。战役、Boss、章节存档、手柄、刻印与最终角色美术属于后续阶段。

项目美术标准见 [docs/ART_STANDARD.md](docs/ART_STANDARD.md)，包括像素规格、调色板、动作拆分、持枪挂点和 UI 反馈；跳跃规则变更见 [docs/jump-update.md](docs/jump-update.md)。
