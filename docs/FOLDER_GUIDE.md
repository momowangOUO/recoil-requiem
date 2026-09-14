# 项目目录与清理记录

- `scenes/`、`scripts/`、`data/`：关卡、游戏逻辑和配置。
- `assets/`：运行素材，以及必须保留的原图、生成提示词和拆件记录。被否决的原始工作稿仍用于说明素材演变，不等同于运行贴图。
- `addons/`：项目内地图编辑器。
- `docs/`：开发标准、排期、检查记录；`screenshots/` 保存正式视觉证据，`references/` 保存策划参考图。
- `game-text/`：审核后的游戏文本草稿。
- `tests/`、`tools/`：回归检查、截图入口和素材处理工具。
- `builds/windows/RecoilRequiem.exe`：唯一 Windows 运行版本。
- `artifacts/`：可重新生成的检查日志、截图和临时文件，不纳入 Git。历史报告中的该目录路径是当时的输出位置，不保证永久保留。
- `.godot/`：Godot 自动生成的本地缓存；`.git/`：版本历史。二者均不是待删除的游戏源文件。

2026-09-11 清理：删除 artifacts 根目录 594 个旧临时文件（95,211,941 字节）及整圈旋转的临时截图序列；保留 docs/screenshots/aim_360.gif 等正式结果。删除未使用的 smg_left_support_v4 运行候选及导入描述，保留其原始生成图和最终 v5。策划文档提取的两张参考图归入 docs/references/。下载技能留下的临时仓库副本暂留 artifacts/natural-writing-zh-source/，整批递归删除被自动审批拦截。

不随意删除 `.import` 和 `.uid`：它们可能是资源导入设置和稳定引用。清理临时截图后，Godot 再次扫描工程会刷新资源索引；不改变实际游戏资源的导入规则。

清理后完整回归全部通过（含 5627 项手臂检查），唯一 Windows 输出已重新导出并启动验证。


2026-09-14：当前AI策划与开发入口统一在dev-design；docs/history保存已撤回旧叙事，原文档路径仅作索引。通用叙事技能源码在tools/skills/game-story-workflow。新NPC未采用的首稿已移除，最终源图/提示词/裁切说明保留；制图脚本移入tools/art，截图夹具移入tests，比较截图移入docs/screenshots。具体清理与唯一运行文件状态以dev-design/VALIDATION.md为准。
