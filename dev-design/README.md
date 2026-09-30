# 开发设定入口

更新：2026-09-30。

本目录用于整合《反冲挽歌》的开发规则、人物、故事、任务和关卡。请先读 [开发规则](DEVELOPMENT_RULES.md) 和 [执行记录](IMPLEMENTATION.md)，再读取与当前任务有关的资料，不要扫描全部文档。叙事技能、新地图、任务和战斗已接入，验收和交付状态见执行记录。

## 已确认方向

- 主角名为莉芙（Líf），两个音节，内部 ID 保持 player；2026-09-14 按用户要求更新。
- 主角是神秘的女性吸血鬼，猎杀同族；所有人物都在游戏过程中结识。用户已选动机 C：对漫长生命如何结束抱有危险的好奇，追猎使她接近同族不愿示人的一面。临终反应不能被旁白认定为客观本性。
- 保留哥特、蒸汽朋克题材，以及真实 3D 场景和精细二维像素人物。人物外观与现有手臂实现约束仍以根 AGENTS.md 和现行美术标准为准。
- 故事偏黑暗、邪道，重要悲剧由人物行动和已建立的世界规则造成。关键损失固定，探索与选择改变部分后果，不预设主角代表正义。
- 全城互通探索；首轮完整制作猩红修道院及连接据点，其他城区先设计连接。
- 保留跳跃、反冲、三枪与六枪槽。扩展空间、路线和遭遇，不靠加血量代替关卡深度。
- “换心维生”“院主出售遗体”已退出默认候选，不得作为正式世界观或新故事的起点。旧搭档、熟人引路等内容也不得恢复。

## 资料优先级

用户最新确认高于旧文档。此处明确确认的内容用于约束新设计；未迁移的旧故事只是历史参考，不自动成为新设定。主入口已运行修道院新版本；其他城区仍为设计提案，不能把待审续篇描述成已开放。

故事工作先读项目 tools/skills/game-story-workflow/SKILL.md，再读取其要求的 game-narrative 和对应角色模板、game-design-natural-writing-zh 与 humanizer-zh。技能调用测试和安装状态见 [验证记录](SKILL_VALIDATION.md)。

## 当前可读资料

- 2026-09-30 章节演出与清晰度修订：[十二段施工表](flow-review/CHAPTER_STAGING.md)、[实施与验证](flow-review/CHAPTER_STAGING_IMPLEMENTATION.md)。对白首帧稳定性、漫画式段落、旧存档和暂停行为以此记录为准。

- 2026-09-30 已按用户确认接入 [12 幅流程示意](flow-review/flow.html)：逐步教学、会面和合作、双路线、发车确认、分战斗恢复及回访。施工与验证现况见 [接入记录](flow-review/IMPLEMENTATION.md)；图稿仍是美术目标，不能把已接入逻辑当作全部视觉细节已经还原。

- 2026-09-22地图建筑、花棚、莉芙人物标题、玩家菜单及存档恢复：[先图后施工记录](IMAGE_LED_WORKFLOW.md)。新增素材来源与实际配准见 [UI来源补记](../assets/ui/v2/SOURCE_2026-09-22.md)；已实现切片不等于全章体验验收，建筑露底与密度仍在推进。

- 开场指引、NPC 交互、纸板建筑与前景修订：[当前实施与验证记录](ENTRY_AND_DEPTH_REVIEW.md)。

- 2026-09-20已接入按图施工的新动线；先读 [实际验证与边界](levels/image-led/VALIDATION.md) 和 [原图与实景对照](levels/image-led/implementation-review.html)：[imagegen生成图与转换施工图](levels/image-led/construction.html)，[独立步行楼梯与布景规则](levels/image-led/README.md)。此前三层长路及跳格栅楼梯设计已被用户否定，不再使用。

- 开发约束：根 AGENTS.md。
- 当前美术与表现：docs/ART_STANDARD.md、docs/VISUAL_IMPLEMENTATION.md。
- 编辑器使用：docs/MAP_EDITOR.md。
- 新重构的范围与状态：IMPLEMENTATION.md。
- 主角动机比较和六卡：[角色审阅](narrative/CHARACTERS_REVIEW.md)。
- 修道院事件、因果和支线：[故事审阅](narrative/STORY_REVIEW.md)。
- 正式交互文本：[对白审阅](../game-text/monastery-v2-review.md)。
- 地图与遭遇布局规格：[空间结构](LEVEL_STRUCTURE.md)。
- 本轮实际地图、接口与验证边界：[地图实施记录](MAP_IMPLEMENTATION.md)。
- 修道院之后的六区连接与续篇候选，待审未实现：[全城与续篇](narrative/CITY_AND_WORLD.md)。
- 不依赖剧情的任务状态接口：[系统规格](SYSTEMS.md)。
- 场景分层与任务 UI 制作约束：[美术与 UI](ART_AND_UI.md)。

主角动机 C 与 STORY_REVIEW.md 事件线已获用户确认，正式接入正在进行。每份内容必须标明“待审”或“已确认”，并保留稳定 ID。
