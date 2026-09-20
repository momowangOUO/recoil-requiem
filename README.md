# 反冲挽歌 · 猩红修道院

> 2026-09-20：主地图改为按生成示意图施工的 image_monastery.tscn（16384px宽）；任务、战斗、暂停与地图 UI 换成同套生成素材。唯一 Windows EXE 已更新并独立启动验证。建筑、通路与 UI 验收边界见 [原图与实景对照](dev-design/levels/image-led/implementation-review.html)、[地图验证](dev-design/levels/image-led/VALIDATION.md) 和 [UI 验收](dev-design/UI_ACCEPTANCE.md)。

使用 Godot 4.7.2 打开 `project.godot`，按 **F5**。唯一 Windows 运行文件为 `builds/windows/RecoilRequiem.exe`。

主角名为**莉芙**，保留已接受的白发、红眼 v5 美术形象。她主动追猎准备离开修道院的维拉。主线、三条支线、交付选择、赛琳战及维拉战已接入；详情见 [开发设定入口](dev-design/README.md) 与 [执行记录](dev-design/IMPLEMENTATION.md)。其他城区仍是明确标注的设计提案，不是已开放内容。

主地图 `scenes/rooms/image_monastery.tscn` 是一张 **16384 逻辑像素宽、16 个空间**的连通区域。建筑依照生成示意图施工，包含门楼、吊车庭、钟楼、泵房、花棚和礼堂。独立楼梯与四条条件开放的货运捷径支持往返。普通石阶用 A/D 行走；钟楼开放金属折返梯下楼时按 S 选择下一段，再继续行走。真实 3D 场景与光影配合二维像素角色，逻辑坐标320×180、世界640×360、角色2倍合成、UI原生分辨率。旧4800px地图和实验室仅用于回归夹具。

敌人包括盾卫、女枪手、突进、投弹、飞行追击、支援六类普通行为，以及精英赛琳和首领维拉。16组遭遇分别承担主线与支路压力，同时主动交战最多6名。遇敌可以绕行，主线没有要求清空整个地图。

## 操作

| 按键 | 行为 |
|---|---|
| A / D | 左右移动，独立于瞄准 |
| Space | 跳跃，能配合反冲；无空中二段跳 |
| W / S | 空中轻微修正；S下穿明确镂空的金属格栅，石台不能穿 |
| 鼠标 / 左键 | 瞄准和射击；左轮、霰弹按次点击，SMG可持续连射 |
| 鼠标靠近画面边缘 | 按当前枪械拉远镜头；所有枪的准心都能到画面边缘 |
| R | 换弹，空弹自动装填，移动与下坠继续 |
| V | 短距离向前爪击；不占枪槽、不耗弹，空中每次落地前只提供一次扑进辅助 |
| 1—6 | 六个固定枪槽；1左轮、2霰弹、3SMG，4—6暂空 |
| Q / 滚轮 | 短按Q或滚轮循环非空槽；长按Q查看 |
| E | 在人物或机关附近交互；交火中先脱离战斗再长谈 |
| J / M | 日志／已探索地图；日志可选择一条支线追踪 |
| M 地图中鼠标拖动／滚轮 | 平移／缩放；点击右侧地点聚焦实际道路；同字母是货运捷径两端，点线表示已开通；上方按钮可回到玩家位置或查看全图 |
| Esc | 关闭日志、地图或对白；游戏中打开暂停面板 |
| Tab | 调参，应用后从检查点重建 |
| Backspace | 返回检查点，保留调查、选择与已完成进度 |
| F9 | 确认后重新开始章节，清除当前章节进度 |
| F6 / F11 | 白模与贴图／窗口与全屏 |

关键调查、交付和检查点自动保存到 Godot 用户目录的 `monastery_v2.json`。死亡和重置恢复检查点、生命和三枪弹匣；未完成遭遇重新开始，已完成遭遇与永久选择保留。换弹、冷却不会通过游戏中的切枪重置。暂停和模态界面冻结物理，并清除旧开火输入。

主线先在外庭找玛拉，再见货梯另一端的维拉。工具箱在货梯间，维修记录在档案走廊；交付需到当事人身边。发车前可以继续探索，确认追猎后未交付支线停止，已有记录仍可查看。最后返回外庭能看到不同选择的后果。

新地图编辑与保存试玩见 [地图编辑器](docs/MAP_EDITOR.md)。运行 `tools/run_checks.ps1` 执行完整检查。实际画面、连续输入回放及验证边界见 [本轮验收](dev-design/VALIDATION.md)。

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

`test_connected.gd` 验证完整地图、四处接缝双向移动与跳跃、滚动角色贴图的坐标、检查点和重置；`test_hit_feedback.gd` 验证受击推力、僵直、打断与连续射击下的恢复。`tests/capture_gothic.gd` 输出三枪四向瞄准、主角与敌人同屏、受击和远处分区的 GPU 渲染截图。

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
| `scripts/combat/` | 扫掠投射物、六类普通敌人、精英与首领、方向性伤害 |
| `scripts/campaign/` | 任务定义、世界状态、对白条件、NPC与检查点保存 |
| `dev-design/` | AI开发入口、已确认设定、待审续篇与实施记录 |
| `tools/skills/game-story-workflow/` | 可维护的通用叙事工作流技能源文件 |
| `scripts/lab/` | 实验切换、场地、相机、音效与反馈 |
| `scripts/ui/` | 独立准星、HUD、暂停调参面板 |
| `tests/` | 无第三方依赖的 Godot 测试与渲染入口 |

`InputFrame` 可注入实际角色控制器；每次有效开火只发出一次 `shot_fired`。`ShotContext` 固定开火时的攻击来源，投射物每帧扫掠路径并只派发一次命中。霰弹的敌人击退总量在七颗弹丸之间分摊，弱点倍率覆盖正侧背倍率。

主入口已接入修道院任务、区域首领和版本化章节存档。其他城区、手柄和刻印仍留在后续范围；旧实验室只用于回归。

项目美术标准见 [docs/ART_STANDARD.md](docs/ART_STANDARD.md)，包括像素规格、调色板、动作拆分、持枪挂点和 UI 反馈；跳跃规则变更见 [docs/jump-update.md](docs/jump-update.md)。

石台默认全实体，不能从底面穿入，S 也不能穿下。只有外观明确镂空的金属格栅可上下穿越。

项目目录用途及清理记录见 [docs/FOLDER_GUIDE.md](docs/FOLDER_GUIDE.md)。
