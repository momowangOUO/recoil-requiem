# 素材目录与保留规则

更新：2026-09-10。

`characters/*` 保存当前人物运行图和仍能重新拆件的制作母版。主角运行时只加载 v5 socket 身体与六张 v3 左右手部件；v4 Gothic 身体、三枪整身试装和 handed 手臂图是当前设计与拆件母版，不能按“代码未直接引用”删除。Aegis 只保留 v3 walk/bash/death，女枪手只保留 v1 idle/shoot/death。

`environments/crimson` 保存二维回归所需的 background_v1/atlas_v1、三维运行所需的 sky_v3/castle_v3/moon_v1 和九张材质，以及三张可重新裁切运行图的 imagegen 母版。`ui` 保存当前准星及其来源说明。

制作母版和来源说明属于仓库内容，但通过 `export_presets.cfg` 排除在 Windows 包之外。文档截图只保留被规范或交付记录引用的代表图；其 `.import` 是可重建缓存，不进入 Git。被否决、已被新版完整替代且不参与当前再生成流程的 PNG 应直接清理，来源标识可留在说明或 Git 历史中。
