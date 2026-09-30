# 修道院章节演出文案

2026-09-30。依据本轮已批准的十二段演出计划；只增加章节字卡与现场提示，沿用正式故事、对白和选择。运行数据为 `data/campaign/chapter_staging.json`。这份稿件不表示对应演出已全部完成。

字卡是界面文字，不是人物突然说出的台词。姓名只在现场初见成立后显示；工具、记录、行李的字卡只在提交结果成功后出现。“暂时保留”不算交付。卡片不解释维拉临终动作，也不替莉芙评价追猎。

| Cue ID | 标题 | 副标题 | 立绘 | 配图 |
|---|---|---|---|---|
| arrival | 猩红修道院 | 维拉今晚要走。沿石阶进入外庭。 | player | entry |
| stairs | 门楼石阶 | 沿石阶前往装卸入口。 | 无 | entry |
| first_guard | 装卸入口 | 穿过入口；上层也有一条路。 | 无 | entry |
| mara | 玛拉 | 货物还没交接完。 | mara | records |
| vira | 维拉 | 她还在收拾行李。 | vira | luggage |
| cooperation | 有人守着上面 | 借赛琳的掩护穿过中庭。 | celine | celine |
| route_lift | 货梯通了 | 沿钟台和档案走廊进入内庭。 | 无 | lift |
| route_service | 隔离杆已落锁 | 沿维护道的楼梯进入内庭。 | 无 | maintenance |
| tools | 工具已交付 | 新开的侧门可以通行了。 | 无 | tools |
| records | 记录已交付 | 维修记录已有接收人。 | 无 | records |
| luggage | 行李已安置 | 看看箱子旁的路，再继续走。 | 无 | luggage |
| departure | 最后一车 | 准备好后，操作发车机关。 | player | departure |
| celine_duel | 赛琳挡住了去路 | 她要让车先走。 | celine | celine |
| celine_after | 路让开了 | 赛琳还活着。追上维拉。 | celine | celine |
| vira_duel | 追上维拉 | 她还想带车离开。 | vira | vira |
| vira_after | 车停了 | 回外庭找玛拉。 | 无 | vira |
| return | 再回外庭 | 交接之后，留下的事还要有人处理。 | mara | return |

## 对白衔接

玛拉与维拉的卡片分别接 `mon.mara.hello`、`mon.vira.hello` 原有对白。赛琳开战卡接 `mon.celine.stop` 至 `mon.player.continue`；根据 `celine_helped` 保留合作或陌生版本。赛琳战后先播放 `mon.celine.defeated`，再让玩家前往维拉所在处。维拉开战接 `mon.vira.fight`、`mon.player.fight`、`mon.vira.answer`。回访仍由 `mon.mara.after` 说明礼堂的损坏。

工具与记录结果先让接收者说完原有回应，再显示短卡。行李只表现现场箱子的位置；维拉不在附近时，不播放她的回应，仍在玩家之后与她交谈时读取对应台词。名字、主线事实及任务条件均保持不变。
