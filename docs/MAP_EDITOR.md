# 地图编辑器

用 Godot 4.7.2 打开工程，在左侧 **Recoil Map** 面板编辑。面板若被关闭，可从“项目 → 工具 → Recoil Map Editor”或“编辑器 → 编辑器停靠面板”重新打开。插件已经随工程启用，无需安装第三方组件。

1. 点击“打开东庭”或“打开钟楼外廊”，进入对应房间的 2D 布局。
2. 输入 X、脚底 Y、平台宽度，添加下穿平台、实体平台、盾兵、女枪手、出生点或出口。
3. 在 2D 视图拖动节点；用 Inspector 修改位置、宽度、碰撞厚度和是否单向。建议启用 Godot 的 16 px 网格吸附。添加操作支持撤销/重做，复制和删除使用 Godot 原生操作。
4. 点击“校验当前地图”。房间范围固定为 X=0–960、可放置脚底 Y=−128–400；只能有一个出生点、一个出口，标记必须放在平台顶部并距端点至少 12 px。
5. 点击“保存并试玩当前地图（3D）”。先保存当前场景，再启动独立游戏窗口，使用真实 3D 场景、武器镜头、二维碰撞及实际敌人。关闭试玩窗口返回编辑。

“场景另存为”可复制出新地图。保存为 `scenes/rooms/*.tscn`，保留根节点的 `crimson_environment.gd` 和 `Gameplay` 子节点。要把新房间接入顺序关卡，在 `RecoilLab.CAMPAIGN_ROOMS` 中添加路径；独立预览不要求先加入战役。

布局保存的是 `PaperPlatform` 与 `RoomMarker` 节点。出生点和敌人位置不再硬编码在关卡控制器里；三维平台由同一份碰撞模块生成，编辑宽度后无需再改一套三维坐标。2D 编辑视图用于摆放与碰撞校验，最终美术、光影及遮挡以“3D 试玩”为准。

这是集成在 Godot 中的开发编辑器，Windows 游戏包不包含编辑功能。当前不支持自由雕刻三维地形、任意大小世界或剧情事件图。校验器检查结构与出生支撑关系，不自动保证每个平台都能到达；关键路线必须用实际控制器测试。

验证入口：`tools/run_checks.ps1` 包含真实编辑器内的添加、修改、撤销、重做、保存和重载检查；GPU 验证另检查面板可见性，截图为 `artifacts/map_editor.png`。

实现依据为 Godot 原生 [EditorDock](https://docs.godotengine.org/en/stable/classes/class_editordock.html) 和 [EditorUndoRedoManager](https://docs.godotengine.org/en/stable/classes/class_editorundoredomanager.html)，没有维护另一份地图文件格式。

## 机关、记录与补给

面板现在可打开全部五间房，并添加 `RoomAction`。在 Inspector 中填写 `action_id`、`title`、`description`；`required` 表示本房出口要求完成该操作。根节点 `require_clear` 控制是否还需要清敌，`objective_hint` 显示当前目标，`architecture` 选择庭院、钟塔、藏书室或花园结构。

平台的 `unlock_action` 留空时始终可用；填写本房的机关 ID 后，平台在该机关激活时启用。标记必须站在初始可用的平台上，不能把开桥机关放到尚未展开的桥上。补给恢复最多两格生命，满血时保留，因此不能设为必做目标。

石台默认为实体。只有勾选 `one_way` 的平台才呈现镂空格栅，并允许上下穿越；两种外观与碰撞由同一个属性控制。校验增加了头顶净空、唯一机关 ID 与桥梁引用检查。调整位置后仍需实际走一次入口、机关和出口，确认能到达也能离开。
