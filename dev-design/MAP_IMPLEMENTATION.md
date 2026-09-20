# 修道院地图实施记录

> 2026-09-20：本文下方为旧平行路网版本的历史实施记录。当前主地图为image_monastery.tscn；实际施工及验证见 [按图施工记录](levels/image-led/VALIDATION.md)。

记录日期：2026-09-14。本文只报告地图、接口与本轮验证；任务、敌人、美术素材和整体完成度由 [IMPLEMENTATION.md](IMPLEMENTATION.md) 汇总。城外区域仍为 [待审规划](narrative/CITY_AND_WORLD.md)。

## 实际范围与预算差异

新场景为 `scenes/rooms/monastery_campaign.tscn`，脚本为 `scripts/rooms/monastery_campaign.gd`。运行类继承 CrimsonEnvironment，但 build 不调用旧房间固定高度的 build。场景中保留真实可编辑的 PaperPlatform、RoomMarker、RoomAction 节点；Gameplay 保存碰撞和玩法点，Sections 保存十六空间的 ID 与边界，Connections 保存连接，VisualSections 保存各层装饰偏移。

当前世界边界是 `Rect2(0, -160, 12000, 2400)`。LEVEL_STRUCTURE.md 的 `18000×2400` 是布局预算，本次保留高度，把宽度收至 12000，即预算宽度的三分之二。缩短的 6000 px 未作为空走廊补回；三条主要高度上下交叠，六组楼梯和下层回收路承担往返。此取舍不代表 12000 是已经调好节奏的最终尺寸，首轮真人试玩后仍须按遭遇密度和撤回距离修订。

|主要站立高度|空间 ID，从左向右|边界与用途|
|---|---|---|
|y=400|mon_04、mon_06、mon_09、mon_13、mon_15|上层侧楼、回廊、钟台、档案和礼堂；x=1600 起接入|
|y=1120|mon_01、mon_02、mon_03、mon_08、mon_14、mon_16|据点、入口、外庭、中央庭院、内庭和后门；贯穿 12000 px|
|y=1840|mon_10、mon_05、mon_07、mon_11、mon_12|运输道、装卸场、货梯、泵房和旧管道；连续地基接住下落|

连接数据采用三条贯通路线及跨层连接，没有逐边复刻 LEVEL_STRUCTURE.md 的每一项邻接。保留十六空间用途、两翼进入、四个远距离捷径及回访目标；原规格中强调的某些直接邻接，在本图中经相邻空间和楼梯抵达。后续地图审阅需检查这类绕行是否仍符合剧情视线和先后关系，不能仅据十六个 ID 宣称原规格全部完成。

## 楼梯、通路与碰撞

六条主楼梯每条横跨 1440 px、升高 720 px。下层到中层的起点 x 为 800、4400、8000；中层到上层的起点 x 为 2400、6000、9600。每组含 30 个踏步，踏步宽 96 px、相邻起点水平错开 48 px、升高 24 px。开放金属格栅允许从下方经过并逐级跳上；其深度为 6 px。上方的长格栅保留同层平路，玩家也能主动下穿。

这组尺寸经过两次实控修订。最初上、下两组入口重叠，角色从上层楼梯入口落到楼梯下方；错开入口后修复。随后返程测试发现石阶下方净空不足，改为可见的开放金属踏步，再把踏步从 48 px 加宽到 96 px，让普通跳跃能稳定落回下一阶。所有普通石路与实体掩体仍从各方向阻挡，未把石材改成单向碰撞。

礼堂后侧另有 x=11600 至 11840 的格栅检修井，连接 mon_15 与 mon_16；它不计入六条斜向主楼梯。井内连续落脚层允许不消耗弹药的纵向返上，主动下穿后落到 y=1120 的道路。该通路补上了礼堂完整石地板原本阻断的下层返程。

四个永久捷径是货运端点之间的转运，不是额外加载的房间，也不应写成角色实时走过了整段远距离轨道。

|门 ID|连接|端点坐标|
|---|---|---|
|gate_entry|mon_02 ↔ mon_10|(2400,1120) ↔ (400,1840)|
|gate_west|mon_04 ↔ mon_08|(2000,400) ↔ (6800,1120)|
|gate_east|mon_09 ↔ mon_14|(7700,400) ↔ (9600,1120)|
|gate_return|mon_16 ↔ mon_01|(11600,1120) ↔ (240,1120)|

每对端点都用 RoomAction 标注，action_id 为相应 `gate_*_travel`，metadata 中记录 `shortcut_gate`；3D 中用货运门框、门槛和操作柄表现。任务系统决定何时开放，地图只查询门状态和目的地。

`gate_departure` 是第五个实体门，位于 x=11040、y=-160 至 424，封住礼堂站立层和右侧楼梯顶部。它与四个货运捷径分开；达到 mon_14 后的主动出发确认由任务系统处理。地图方法本身不推断剧情条件。

## 运行接口

|接口|内容|
|---|---|
|space_bounds|空间 ID 到 Rect2 的字典；space_at(point) 返回该点所属 ID，越界为空字符串|
|connections|字典数组，含 from、to、gate_id、position；未设门时 gate_id 为空|
|checkpoints|字典数组，每项含 id、space_id、position；不同于旧 ConnectedMonastery 的 Vector2 数组|
|npc_points / action_points|字典数组，含 id、space_id、position；首次相遇、任务可用性由 session 控制|
|enemy_spawns|48 个初始编辑标记，组成 16 组遭遇；每个标记含 encounter_id、space_id、room_id、enemy_archetype|
|gates / gate_states|实体门对象与对应开闭状态；set_gate_state(gate_id, opened) 同步碰撞与可见性|
|shortcut_points|四组端点的坐标与空间 ID|
|shortcut_destination(point, radius=48)|门开启且靠近端点时返回另一端坐标；否则返回 Vector2.INF|

标记保留现有 SHIELD/RIFLE 枚举作为编辑器占位类别，具体行为由 enemy_archetype 区分 shield、rifle、charger、grenadier、flyer、support、elite、boss。第 12 组 mon_15 包含 boss 标记；遭遇激活上限与敌人实现归任务和战斗模块，本文件不将 48 个标记等同于 48 名同时交战的敌人。

机关点已提供 tools、records、luggage、departure、exit 及 gate_*。tools 和 records 的现场标题直接采用已审文本“找到伊娜的工具箱”“找到闸门的维修记录”。本轮交接时发现 tools 最初误放在 mon_05，主集成方已按 STORY_REVIEW.md 改为 mon_07 的 (6240,1840)，并同步 space_id。文本和事件状态的最终解码检查由总验收负责。

## 3D 表现修订

CrimsonStage3D 增加 campaign_enabled，启用时在加入 simulation 前传给游戏实例。旧房间夹具默认不启用，原坐标和回归条件保留。新主场景由 GamePresentation 选择 campaign。

镜头原先将纵向目标限制在 -20 至 350，现在新地图按其完整 bounds 跟随。角色合成原先固定 y=144，只移动横向窗口；新地图会同时移动纵向窗口。仍使用 1920×1088 的固定透明合成目标与 2 倍采样，角色没有随地图面积放大。

VisualSections 为每层提供偏移。柱、烛台、书架和花盆的支承查询只接受当前层附近的平台；缺少两侧支柱的铃架不生成。底层道路带连续地基，中上层仍按实际薄板深度绘制，避免假地基遮住下一层角色。近景沿底层下方扩展，远处城堡延长到整图宽度，月亮仍只有一个。实体掩体会遮住其后的角色，这是几何遮挡；掩体位置和识别性仍需遭遇试玩复核。

## 验证记录与边界

本轮实际执行引擎：Godot 4.7.2 stable，Windows；3D 使用 Compatibility/OpenGL，设备为 NVIDIA GeForce RTX 3070。先运行缺少新场景的失败测试，再实现地图。主测试为 `tests/test_monastery_campaign.gd`。

|验证|本轮实际结果|
|---|---|
|十六空间、检查点归属、无可选捷径的连接图遍历|通过|
|五门打开移除碰撞、关闭恢复碰撞|通过|
|四货运接口两向目的地、锁闭返回不可用|通过；这验证地图接口，不等于完整 E 键剧情流程回放|
|六条整段楼梯上行|门已开放，responsive 控制器、60 Hz、不开火，通过|
|上、中、下三层长路线各双向穿越|门已开放，真实 CharacterBody2D 与 InputFrame，共六条，通过；下层跳越实体掩体|
|礼堂门锁闭阻挡全身、开启后通过|通过|
|礼堂后部检修井上下行|不开火上行及主动下穿落到后门道路，通过|
|三层 × 三枪 × 最近/最远镜头|真实 OpenGL 输出 18 张图，镜头距离与合成窗口检查通过|

数据与路线命令：

```powershell
& D:/godot/Godot_v4.7.2-stable_win64_console.exe --headless --path D:/recoil-requiem --fixed-fps 60 --script res://tests/test_monastery_campaign.gd
```

渲染命令：

```powershell
& D:/godot/Godot_v4.7.2-stable_win64_console.exe --path D:/recoil-requiem --fixed-fps 60 --script res://tests/test_monastery_campaign.gd -- --campaign-render
```

18 张截图在 `artifacts/monastery_layer_{1..3}_weapon_{0..2}_{near|far}.png`。抽查了中层左轮远镜头、上层霰弹近镜头、底层 SMG 远镜头；程序检查覆盖所有 18 组，不等于逐张完成完整美术验收。礼堂后部检修井在这批截图之后补入，已通过物理测试，但本轮未单独截取该处新画面。

渲染执行时，其他工作项仍在生成 NPC 的 campaign 图像，日志出现 boss.png、elite.png 等尚未产出文件的加载错误；地图镜头断言通过不抹去这些资源错误。旧 test_stage_3d 曾在 headless 下出现鼠标注入坐标断言失败，已向主集成方报告，不能在本记录中写成全回归通过。整体 tools/run_checks.ps1、资源到齐后的复测和唯一 Windows 导出由主集成方执行。

测试没有覆盖每条战斗进场、所有捷径的完整任务触发、首次玩家迷路情况、连续高反冲穿越、通关战斗的性能及全部 NPC 状态。机器人按脚本跳跃的结果仅说明几何路线可达，不能代替首次真人试玩。

首轮渲染夹具未禁用 campaign autosave，可能向 user://monastery_v2.json 写入测试到访；发现后已通知主集成方，夹具现在进入场景后设置 autosave=false。没有擅自删除该文件。后续验收应使用独立存档或先保留用户存档，避免把测试状态当成正常游玩进度。
