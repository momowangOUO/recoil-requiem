# 修道院完整流程 新增与调整文案草稿

状态：完整流程已获用户批准，2026-09-30 接入。已有对白沿用 monastery-v2-review.md；这里只列完整流程稿新增或拟替换内容，新增 ID 使用 mon.flow.*；既有 ID 的调整列在文末，按本次批准的流程接入。

| 拟用 ID | 条件／说话人 | 草稿 |
|---|---|---|
| mon.flow.opening.intent | 莉芙；已知维拉准备离开 | 都要走了，还在搬东西……我倒想看看她带了什么。 |
| mon.flow.entry.cross | 第一场交锋目标；不要求击杀 | 穿过装卸入口，进入外庭 |
| mon.flow.route.find | 见到维拉后 | 寻找通往内庭的路 |
| mon.flow.route.choose | 接触两路信息后 | 开通一条通往内庭的路 |
| mon.flow.route.lift | 选择维修路线 | 检查货梯卡住的位置 |
| mon.flow.route.service | 选择维护路线 | 沿维护道进入内庭 |
| mon.flow.celine.job | 赛琳；首次合作前 | 玛拉雇我看着交接。货没交完，谁也别把路堵了。 |
| mon.flow.celine.cross | 合作段目标 | 与赛琳穿过中庭 |
| mon.flow.ina.side_door | 伊娜；交还工具后 | 箱子给我。旁边这扇门，我来修。 |
| mon.flow.tools.done | 侧门开启后；不得在尚未开门时显示 | 工具已交还伊娜；维护侧门已开放。 |
| mon.flow.departure.ready | 已到安全整备区 | 准备好后，操作发车机关 |
| mon.flow.departure.title | 确认界面 | 继续追猎？ |
| mon.flow.departure.body | 确认界面 | 继续后，尚未完成的物品交接将结束。已经读过的记录和打开的通路会保留。 |
| mon.flow.departure.tools | 工具已取得但未交付 | 工具箱尚未交还。 |
| mon.flow.departure.records | 记录已取得但未交付 | 维修记录尚未交给任何人。 |
| mon.flow.departure.luggage | 已受托但未处理 | 还没有按维拉的要求搬动箱子。 |
| mon.flow.departure.go | 独立确认按钮 | 继续追猎 |
| mon.flow.departure.wait | 返回按钮 | 再等等 |
| mon.flow.celine.warning | 赛琳；发车确认后，交战前 | 到这里了。再往前，我得拦你。 |
| mon.flow.chapter.explore | 章节完成按钮 | 继续探索修道院 |
| mon.flow.chapter.title | 章节完成按钮 | 返回标题 |
| mon.flow.next_region.closed | 检查后门；无下一区域实现 | 门外通向旧运输线。后续区域尚未开放。 |

附加规则：未取得物品时不谎称玩家持有；未受托搬箱时不列为未完成承诺。发车面板可写“还有未调查的线索”，但不能泄露陌生人物或未知道具位置。已提交的归属只显示结果，不再提供交付按钮。跳过对白不自动替玩家选择。

阅读与复核：采用项目 game-story-workflow；已按 game-narrative 和本地适配规则检查角色知识与因果，使用 Narrative Designer 独立审查。中文复核依 game-design-natural-writing-zh 与 humanizer-zh，未改变正式事实或状态 ID。

## 接入复核补记（2026-09-30）

以下文案补足已批准流程的现场反馈与按键占位符；伊娜只说明维修步骤，鲁卡只说明自己负责的设备，不提前判断交付结果。

| ID | 运行文案 |
|---|---|
| mon.action.lift_repair | 货梯维修台 |
| mon.action.maintenance_isolate | 安全隔离杆 |
| mon.flow.repair.need | 先找伊娜问清卡榫的修法，再带工具箱来。 |
| mon.flow.repair.delivered | 工具箱已经交出去了。维护道仍可通行。 |
| mon.flow.repair.done | 货梯卡榫已松开，货运近路已开放。工具箱仍由你保管。 |
| mon.flow.route.upper | 沿钟台和档案走廊进入内庭 |
| mon.flow.route.lift.choice | 走货梯和钟台一侧 |
| mon.flow.route.service.choice | 走泵房维护道 |
| mon.flow.service.safe | 隔离杆已落锁。沿维护道的楼梯前往内庭。 |
| mon.flow.route.other | 另一条入口仍可探索；在现场机关或日志里可以改选路线。 |
| mon.flow.luggage.preview | 搬回旧房后，低处通道会空出来；留在装卸位置，箱子会挡住这条射线。 |
| mon.flow.chapter.records | 已调查维修记录。 |
| mon.flow.chapter.lift | 货梯近路已开放。 |
| mon.flow.chapter.service | 泵房维护道已开放。 |
| mon.flow.chapter.celine | 赛琳仍留在外庭。 |
| mon.flow.tutorial.move | {key} / {key2}　移动 |
| mon.flow.tutorial.jump | {key}　跳跃；低箱旁有落脚台 |
| mon.flow.tutorial.shoot | {key}　开火；反冲会把你推向后方 |
| mon.flow.tutorial.reload | {key}　换弹；先找掩体 |
| mon.flow.tutorial.claw | {key}　爪击，拉开近身距离 |
| mon.flow.tutorial.switch | {key}　切枪；长按查看枪槽 |
| mon.flow.tutorial.map | {key}　查看附近道路 |
| mon.main03.title | 寻找通往内庭的路 |
| mon.main03.hint | 货梯维修可开近路，泵房维护道不需要工具；两路都通向内庭。 |
| mon.ina.tools | 箱子在里面。先把货梯卡榫松开；用完以后，箱子的归属再说。 |
| mon.ina.returned | 箱子给我。旁边这扇门，我来修。 |
| mon.tools.returned.notice | 工具已交还伊娜；维护侧门已开放。 |
| mon.ruka.route | 泵已经停了。拉下隔离杆，沿维护道的楼梯走，就能到内庭。 |
| mon.main04.title | 准备好后，操作发车机关 |
| mon.exit.notice | 门外通向旧运输线。后续区域尚未开放。 |

执行记录：已读项目 game-story-workflow、已安装 game-narrative 及 local-adaptation / narrative-designer、game-design-natural-writing-zh 与 humanizer-zh。先核对现场操作及角色知识，再复核中文；保留名称、任务键、固定结局与 {key}/{key2}。运行 JSON 与本文逐项核对。

| ID | 运行文案 |
|---|---|
| mon.flow.key_space | 空格 |
| mon.flow.key_mouse_1 | 鼠标左键 |
| mon.flow.key_mouse_2 | 鼠标右键 |

| ID | 运行文案 |
|---|---|
| mon.ruka.records | 这份留给我。交接的价钱还没谈，我得让他们知道这些地方怎么修。 |
| mon.mara.records | 先放我这里。交接前，我让鲁卡拿着它给新人讲一遍。 |

| ID | 运行文案 |
|---|---|
| mon.flow.tutorial.shotgun | {key}　近身开火，用反冲换位 |
| mon.flow.tutorial.smg | {key}　空中开火，减缓下落 |
