# 地图编辑器

2026-09-20 更新：主入口使用 `scenes/rooms/image_monastery.tscn`，包含 16 个空间，世界边界为 `Rect2(0,-2080,16384,6200)`。旧 `connected_monastery.tscn` 和五个 960 px 分区继续作为编辑与回归夹具保留。

用 Godot 4.7.2 打开工程，在左侧 **Recoil Map** 面板编辑。面板关闭后，可从“项目 → 工具 → Recoil Map Editor”或“编辑器 → 编辑器停靠面板”重新打开。插件已随工程启用。

1. 点击“打开新版修道院（16空间）”。Gameplay 下保存平台、人物标记与机关，Sections 保存空间边界，Connections 保存连接，StructureRecords 保存源图建筑结构，StoryPositions 保存剧情专用位置。旧“打开整张修道院地图”仍打开 4800 px 组合夹具。
2. 输入 X、脚底 Y、平台宽度。新图放置范围随根节点 `world_bounds` 元数据读取：X 为 0 至 16384，Y 为 -2080 至 4119；校验还会检查平台整个碰撞矩形是否在边界内。切换旧地图后，控件恢复相应宽度与 -128 至 400 的旧高度范围，不执行 gameplay build 来计算边界。
3. 添加实体平台、下穿平台、盾兵或女枪手。新图另有突进、投弹、空中、支援四类敌人按钮；选择“遭遇组 ID”后放置，节点会保存 enemy_archetype、encounter_id、space_id、room_id。空间 ID 由当前放置点所在的 Sections 边界取得，遭遇组范围为 1 至 16。旧房间不接受这四类战役按钮。
4. 在 2D 视图拖动节点，用 Inspector 改宽度、碰撞厚度、单向属性和 Metadata。16 px 网格适合石路；独立 PaperStair 用 end_offset 定义水平长度和高差，最大坡度 35°；踏步与连续梯面共享端点，不再用一串小平台拼楼梯。添加操作支持撤销与重做，复制、删除使用 Godot 原生操作。
5. 点击“校验当前地图”，修复报错后再保存。标记脚底必须落在初始可用的平台顶面，并距端点至少 12 px；角色上方留出 38 px 净空。校验不会自动证明整条路线可达。
6. 点击“保存并试玩当前地图（3D）”。新版正式场景保存后直接启动主入口，因此包含任务、NPC、遭遇激活和门状态。关闭游戏窗口返回编辑。

## 出生、检查点和 NPC

正式地图有且仅有一个真正的 SPAWN 和 EXIT。新图的 PlayerSpawn 位于 (960,1120)，WorldExit 位于 (16080,1424)。它们不带 npc_id 或 checkpoint_id。

检查点和 NPC 为沿用编辑器标记显示，可以继续使用 Kind.SPAWN，但分别带 `checkpoint_id` 或 `npc_id` 元数据；校验器不会把它们计为玩家出生点。一个标记不能同时属于这两类。NPC、检查点与地面敌人仍须满足脚底支承和站立净空要求，元数据不能豁免实际悬空或墙体重叠。

新敌人仍使用现有 SHIELD/RIFLE 枚举作为编辑显示类别，具体行为读 enemy_archetype。调整位置后检查 space_id、room_id 与遭遇组是否仍正确；拖动节点不会自动改这些元数据。复制一个标记也会复制它所属的遭遇组，不能把复制理解为自动创建新遭遇。

## 机关、记录与货运通道

RoomAction 的 action_id 必须非空。普通机关、记录和补给的 ID 不能重复。填写 title、description 前先确认相应玩家文本已审阅；开发按钮创建的占位标题不能直接作为正式对白交付。

平台 unlock_action 留空时初始可用，填写机关 ID 后在该机关激活时启用。标记不得依赖尚未启用的平台作为唯一支承。补给不能设为必做目标。石路从各方向阻挡，只有 one_way 平台呈现镂空金属格栅并允许下穿。

四条货运通道使用成对的 RoomAction，例如两个 `gate_entry_travel` 端点均有 `shortcut_gate="gate_entry"`。只有这种相同 ID、相同现有门 ID、恰好两个不同位置的组合允许重复 action_id。单端、三端、混入普通机关、引用不存在的门或两端引用不同门，都会报错；同一门跨多个 action_id 凑出更多端点也不允许。

实体门用 PaperPlatform 的 gate_id 标记。门 ID 唯一，关闭的门不能设为单向，门体必须与已有支承接触。出生点或敌人进入关闭门体仍会报重叠；仅属于该门的货运操作点可位于对应门洞中。这样的操作点依然要有独立、初始可用的脚底支承，不能站在会消失的门体上。

`gate_departure` 与 `gate_departure_back` 封住礼堂前后入口，不能把后者当成普通重复门删掉。四条货运通道的开放与最终出发事件由战役状态决定，编辑器不替任务系统修改结果。

## 旧分区与地图副本

旧组合地图的 Sections 引用五个源场景。编辑源场景仍会改变该组合地图，校验器按组合后的坐标检查，并只保留组合起点和终点的出生/出口语义。五个源分区的传统唯一机关、解锁引用、头顶净空规则保留。

“场景另存为”可以生成 `scenes/rooms/*.tscn` 副本，保持脚本和必要子节点。普通旧房间通过 `--room=路径` 独立预览；尚未加入顺序关卡也可试玩。新版战役副本目前仅用于布局预览，不承诺按副本初始化完整 NPC、任务或新敌人行为；本轮完整战役试玩仅支持正式 `image_monastery.tscn`，不要用副本预览结果验收剧情。

地图编辑器是 Godot 内的开发工具，Windows 游戏包不包含编辑功能。它编辑共享的二维碰撞与玩法节点，三维平台由同一数据生成；最终遮挡、光影、角色辨认和路线仍在真实 3D 试玩中验收。自由雕刻三维地形、自动路径证明与剧情事件图不属于当前功能。

## 验证

`tests/test_campaign_editor.gd` 不执行地图 build，检查新图结构、元数据、货运双端限制，以及普通重复 ID、无支承 NPC/敌人、关闭门体重叠、悬空门和越界的拒绝行为；同时重跑五个旧分区与旧组合图的校验。

真实编辑器流程：

```powershell
& D:/godot/Godot_v4.7.2-stable_win64_console.exe --headless --editor --path D:/recoil-requiem --quit-after 900 -- --campaign-editor-smoke
```

该流程验证新图打开、16384 px 控件范围、四类敌人元数据、保存重载与撤销，并切回 4800 px 旧图验证范围恢复。只写 `artifacts/campaign_editor_roundtrip.tscn`，不保存测试添加的敌人到正式场景。原 `--map-editor-smoke` 继续验证旧编辑流程。

本轮新校验与新编辑器烟雾测试通过；GUI 视觉可见性未单独截图，不以 headless 编辑器测试替代面板美术检查。平台可达性与三层镜头结果见 [地图实施记录](../dev-design/MAP_IMPLEMENTATION.md)。

实现使用 Godot 的 [EditorPlugin.scene_changed](https://docs.godotengine.org/en/stable/classes/class_editorplugin.html#class-editorplugin-signal-scene-changed)、[EditorDock](https://docs.godotengine.org/en/stable/classes/class_editordock.html) 和 [EditorUndoRedoManager](https://docs.godotengine.org/en/stable/classes/class_editorundoredomanager.html)。

## 独立楼梯

面板可设置楼梯水平长度和高差，添加楼梯或修改当前所选楼梯；操作支持撤销、重做与保存重载。石阶默认实体，既阻挡脚底也阻挡头顶。仅外观明确镂空的金属梯可开启 one_way，沿用 S 下穿。钟楼上下梯段在二维平面重叠，A/D 行走梯面，上楼在接台折返，下楼在梯段内侧按一次 S 选择相邻下梯，不需要跳跃或射击。

飞行敌人无需地面支承，但仍检查世界边界和实体净空。

楼梯编辑器测试入口为 --stair-editor-smoke；tests/test_image_editor.gd 校验实际主地图，tests/test_stair_editor.gd 覆盖斜面、净空和飞行单位例外。tools/run_checks.ps1 已纳入这些入口。
