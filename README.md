# 反冲挽歌 反冲手感实验室

Godot 4.7.2 / GDScript / Windows 键鼠灰盒原型。三把枪分别验证单发修正、爆发位移和持续缓降；银盾祷姬验证绕背、弱点和击退。

用 Godot 4.7.2 打开 `project.godot`，按 **F5**。项目直接进入实验室，不需要安装插件或下载素材。主角使用 imagegen 生成的像素精灵，场景保留灰盒；枪声在运行时合成。

## 操作

| 按键 | 行为 |
|---|---|
| A / D | 左右移动，与瞄准独立 |
| Space | 地面跳跃，可与开枪反冲叠加；无空中二段跳 |
| W / S | 空中轻微修正；W 不起跳，S 可下穿青色单向平台 |
| 鼠标 / 左键 | 独立瞄准 / 射击；左轮和霰弹按次点击，SMG 按住连射 |
| R | 换弹；空弹自动装填，空中继续下坠 |
| Q / 滚轮 | 切换两个装备槽 |
| F1 / F2 / F3 | 机动 / 缓降 / 盾兵实验，切换后重置 |
| Backspace | 重置当前实验 |
| Tab / Esc | 打开调参面板 / 暂停；再次按下恢复 |
| F11 | 切换全屏 |

Space 跳跃，向下开枪继续抬升；朝移动方向开枪刹车，反向开枪加速。支持 0.10 秒离台宽限和落地前输入缓冲，按住 Space 不会连续自动跳跃。地面枪械反冲会受到正常地面刹车影响，空中保留更多动量。

默认使用 **Responsive** 参数：跳跃高度约 75 px，落地比初版更快；地面有更强的刹车和水平反冲吸收，空中方向输入有 220 px/s 巡航上限，松手后逐渐减速。枪械反冲仍可突破巡航速度。Tab 底部 **GDD** 恢复旧参数，**Responsive** 恢复当前默认，两者均重置当前实验。调整详情和对照数据见 [docs/movement-feel.md](docs/movement-feel.md)。

准星周围的圆环显示真实换弹进度，随时间从红橙经过金黄变为青绿。霰弹每颗装填重新计一圈；HUD 同时显示换弹百分比、当前弹格、备用枪弹量和五格生命。

## 试玩顺序

1. **F1 机动：** 先用 Space 跳过 16 PX 台阶，再试 Space 起跳后左轮朝下开枪登上 96 PX 平台；Q 切换霰弹枪，比较单独反冲与跳跃叠加的高度。跨过右侧 160 PX 缺口，在落点前向右射击刹车。
2. **F2 缓降：** Tab → Weapons 将一个槽装备为 HYMN，Apply。选中 HYMN 后，按 S 穿过起始平台，向下持续开火；用 Backspace 重置并比较自由落体。24 发用尽后的装填间隔会明显加快下坠。
3. **F3 战斗：** 盾兵正面伤害低；观察盾击预警，利用霰弹升空越过她，落到背后再开火。收招时后腰红色弱点开放。Tab → Trial 可切换固定朝向靶子，隔离测量正侧背伤害。靶子仍接受物理击退。

## 调参规则

- Movement：重力、跳跃冲量（当前默认 545；GDD 为 460）、地面加减速、空中控制、方向输入巡航速度、空中松手减速、地面水平反冲比例、终端下落速度、速度软上限和超速阻尼。空中垂直修正最多为重力的 80%，防止 W 产生免费飞行。
- Weapons：两把不同的装备，以及每把枪的反冲、射速和换弹时间。霰弹的换弹时间是每颗弹壳的时间。
- Trial：固定靶/活动盾兵、转身速度、物理测量模式和震屏。测量模式关闭震屏；原型不使用全局停顿改变物理时间。
- Apply 会重置实验；GDD 恢复文档参数，Responsive 恢复当前默认。**修改仅保留在本次运行内，关闭游戏会丢弃调参结果。** 数据资源不会被面板写回。
- 切枪保留各枪的弹量和射击冷却。打断装填后切回原枪，会重新开始未完成的装填过程；已经装好的霰弹保留。
- 默认内部画布 320×180，以整数倍放大。非整数匹配的窗口尺寸会留黑边；场景使用最近邻采样。

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
| `scripts/player/` | 键鼠采集、CharacterBody2D 控制器、双槽武器控制 |
| `scripts/combat/` | 扫掠投射物、盾兵状态机、方向性伤害 |
| `scripts/lab/` | 实验切换、场地、相机、音效与反馈 |
| `scripts/ui/` | 独立准星、HUD、暂停调参面板 |
| `tests/` | 无第三方依赖的 Godot 测试与渲染入口 |

`InputFrame` 可注入实际角色控制器；每次有效开火只发出一次 `shot_fired`。`ShotContext` 固定开火时的攻击来源，投射物每帧扫掠路径并只派发一次命中。霰弹的敌人击退总量在七颗弹丸之间分摊，弱点倍率覆盖正侧背倍率。

当前交付是反冲实验室。战役、Boss、章节存档、手柄、刻印与最终角色美术属于后续阶段。

项目美术标准见 [docs/ART_STANDARD.md](docs/ART_STANDARD.md)，包括像素规格、调色板、动作拆分、持枪挂点和 UI 反馈；跳跃规则变更见 [docs/jump-update.md](docs/jump-update.md)。
