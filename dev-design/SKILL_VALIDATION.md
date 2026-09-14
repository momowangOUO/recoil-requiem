# 技能验证记录

2026-09-14。基线在独立 skill_baseline 会话运行，未读取新建 wrapper，允许使用现有技能。基线不是绕开所有系统规则的裸模型。

## 基线实际结果

|用例|观察|
|A|直接假设“阻止院主继续伤人”，写出“把门打开，让他们走”。未经人物动机比较，默认救援立场。失败。|
|B|新增伤口和流血，未标明新事实；仅凭受伤强化黑暗感。失败。|
|C|给出保住修道院和拒收难民，但秘密与拒绝缘由仍待定，没有完整人物卡。失败。|
|D|正确撤回两项设定，没有假称清理旧稿；新任务仍是通用护送框架。撤回检查通过。|
|E|保留 task_id=gate_03、2、低于30、且、{npc_name}。通过。|
|F|“她处理这件事时有些犹豫。”范围正确。通过。|
|G|要求错误栈与代码，使用技术技能。通过。|
|H|实际搜索缺失依赖，不宣称读取。通过。|

基线实际读取：.agents/skills/game-narrative/SKILL.md、local-adaptation.md、narrative-designer.md、psychologist.md；.codex/skills/humanizer-zh/SKILL.md；G 另读 systematic-debugging。未读取 game-design-natural-writing-zh。批量结果中 psychologist 部分截断，测试者明确未宣称完整读取。

新技能据此补充最小动机前置、十字段卡、暗黑扩写标注与真实读取要求；通过项保留为回归项。后续填写复测结果，不预先宣称通过。

## 显式加载复测

独立 skill_green 会话实际读取新技能及验收案例，没有读取基线记录。复测 A 先询问具体欲望，没有写正义前提的对白；B 标明新规则是提案，用制度后果代替追加伤亡；C 提供十字段完整提案，含知识边界与具体行为；D 明确撤回，不假称编辑未提供的旧稿。E 原样保留条件与 ID，F 只改一句，G 转向技术信息，H 实际检索后报告依赖缺失。

复测八项均满足相应检查。C 的人物并非本游戏人物；不得把测试卡里的儿童、人名和设定迁入本项目。A 请求必要动机，不表示用户批准的本项目三种动机比较也要先询问。

实际读取路径：项目 SKILL.md、acceptance-cases.md、character-card.md、event-card.md；.agents/skills/game-narrative/SKILL.md、local-adaptation.md、psychologist.md、narratologist.md、narrative-designer.md；.codex/skills/game-design-natural-writing-zh/SKILL.md 与 humanizer-zh/SKILL.md。首次截断的文本随后单独重读。

基线与复测是两个独立会话；各自八用例共享该会话，不能声称八对隔离实验。G 的复测没有为技术任务新读叙事技能，但此前其他用例读入的内容仍在上下文，因此另做纯技术独立路由检查。上述结果仅证明显式读取后的行为，不保证隐式触发。

依赖路径辅助脚本通过 7 项检查：空目录缺失、优先 .agents、回退 .codex、缺失退出码、三种模式实际定位。脚本输出明确是 located_not_invoked。官方 quick_validate.py 缺少 PyYAML，未成功运行；不为一个检查器新增项目依赖，使用本包固定结构的无依赖静态检查替代并记录范围。

## 安装与项目路由

固定包结构检查通过：name/description、所需参考文件、元数据引号、显式入口、隐式调用配置及没有假 MCP 依赖。不是通用 YAML 解析器。已安装到 C:/Users/liyian.andy/.agents/skills/game-story-workflow，源包全部文件与安装包 SHA256 一致。

独立 skill_route_check 会话从项目 AGENTS 正常读取工作入口，实际选中 wrapper 及 game-narrative、本地适配、角色卡模板、Psychologist、中文策划与润色技能，交付了有行为/认知边界的角色提案。这证明项目显式路由有效，不证明系统目录已经热加载新技能。

独立 skill_negative_check 会话只读 AGENTS，对纯脚本检查请求给出技术检查方案，没有读取 wrapper 或 game-narrative。负例与其他故事请求不共享会话上下文。

验证范围：2 次八用例会话，1 次项目正例，1 次隔离技术负例，7 项路径辅助脚本检查，固定包结构和安装一致性检查。没有声称能够百分之百保证所有未来请求自动选择技能。
