# 修道院动线与对白修订稿

2026-10-27。依据已确认的STORY_REVIEW事件线修订，覆盖当前修道院章节的目标、交互、对白和演出短句。实施稿；运行接入与验证结果见开发记录。下表为本轮文字依据，旧稿保留作历史。

莉芙主动追猎，想亲眼看维拉临走时的选择；不新增雇主、营救或善恶评判。玛拉忙于接收货场，伊娜要拿回工具，鲁卡守着需要交班的机器。赛琳先提供掩护，再履行交接工作阻拦莉芙，战败后存活。维拉拒绝交代私事，最终死亡不变。人物在本章初识，不知道尚未调查的物品内容。

主路从门楼到装卸庭，再选货梯或泵房进入内庭；钟台顶与档案室是可选探索。初见维拉时，她站在关闭的货梯门另一侧。工具交出前若尚未修好货梯，选项明确说明之后走泵房。发车前仍保留未完成交接的后果；不加入倒计时。

## 运行文字

|ID|文字|
|---|---|
|mon.opening.target|维拉今晚离开修道院。|
|mon.opening.intent|趁车还没开，我想见见她。|
|mon.ui.opening_controls|A / D　移动　空格　跳跃<br>鼠标　瞄准　左键　开火|
|mon.ui.controls|E　交谈／调查　J　日志　M　地图|
|mon.ui.completed|已完成：{objective}|
|mon.ui.end_talk|离开 · Esc|
|mon.ui.interact|E　{action}{target}|
|mon.action.tools|工具箱|
|mon.action.records|维修记录|
|mon.action.luggage|无标签的箱子|
|mon.action.departure|发车杆|
|mon.action.exit|后门|
|mon.action.shortcut|货运侧门|
|mon.action.gate|侧门机关|
|mon.main01.title|穿过门楼，找人问路|
|mon.main01.hint|从运输站向右，沿门楼石阶下到装卸庭。维拉的车还没走。|
|mon.mara.hello|找路？正门已经关了。|
|mon.player.entry|我从货道进来的。|
|mon.mara.ask|你找谁？|
|mon.player.target|维拉。她还在这里？|
|mon.mara.target|她在右边的货梯口，车还没装完。|
|mon.mara.repeat|她就在货梯的铁门后面，一直往右走。|
|mon.mara.waiting|我还得清点货物，有东西要交就放这儿。|
|mon.main02.title|到右侧货梯口找维拉|
|mon.vira.hello|别堵着门。还有一车没装。|
|mon.player.hunt|我是猎人，来找你的。|
|mon.vira.recognize|玛拉让你来的？|
|mon.player.confirm|我自己来的。|
|mon.vira.reply|那就等着，货还没装完。|
|mon.player.luggage|你要带走这么多？|
|mon.vira.luggage|还没分完。别动那些箱子。|
|mon.main03.title|打开通往内庭的路|
|mon.main03.hint|修货梯需要伊娜的工具。装卸庭格栅下方还有一条泵房通路。两路都能进内庭。|
|mon.ina.hello|找工具箱？你要修什么？|
|mon.player.tools|货梯的门卡住了。|
|mon.ina.tools|工具箱在右边低处。拿去修卡榫，用完记得还我。|
|mon.ina.repeat|灰铁箱，断了半边提手的那个。|
|mon.ruka.hello|找上去的路？|
|mon.player.route|从这里能进内庭？|
|mon.ruka.route|往右。拉下隔离杆，就能上楼了。|
|mon.ruka.ready|隔离锁已经扣住了，沿右边的楼梯上去。|
|mon.celine.hello|先别过去，对面架着枪。|
|mon.player.cover|你是替谁守着这儿？|
|mon.celine.cover|你过去吧，我盯着对面的枪手。|
|mon.player.return|侧门开了。可以绕回去了。|
|mon.celine.return|看见了。你先走。|
|mon.tools.title|取回伊娜的工具箱|
|mon.tools.inspect|箱盖刻着“伊娜”，封条却写着“仓库资产”。|
|mon.tools.return.choice|交还工具箱|
|mon.tools.keep.choice|把工具箱交给玛拉|
|mon.tools.return.unused.choice|交还工具，改走泵房|
|mon.tools.keep.unused.choice|交给玛拉，改走泵房|
|mon.tools.later.choice|先留着工具箱|
|mon.ina.returned|给我吧。我去开旁边的侧门。|
|mon.ina.withheld|你把我的箱子给她了？|
|mon.mara.tools|放这儿。仓库侧门的锁，我叫人开。|
|mon.tools.returned.notice|工具已交还伊娜。维护侧门已开。|
|mon.tools.kept.notice|工具已交给玛拉。仓库侧门已开。|
|mon.records.title|查看并交接维修记录|
|mon.records.note|右侧摇柄要转到底，隔离锁才会扣住。换过轴套后仍有偏斜。交班前请当面试一次，不要照旧图操作。|
|mon.records.ruka.choice|把记录交给鲁卡|
|mon.records.mara.choice|把记录交给玛拉|
|mon.records.keep.choice|先留着记录|
|mon.ruka.records|交给我吧，得留给接班的人看。|
|mon.mara.records|我收着。交班时让鲁卡照这个讲。|
|mon.records.read.notice|维修记录已收进日志。|
|mon.luggage.title|安置维拉留下的箱子|
|mon.luggage.tag|箱子没贴标签，锁扣也没扣。里面装着旧衣服和用过的日用品。|
|mon.vira.request|那箱没标签的搬回旧房，我不带了。|
|mon.luggage.return.choice|搬回旧房一侧|
|mon.luggage.leave.choice|留在车旁|
|mon.luggage.defer.choice|暂时不搬|
|mon.vira.returned|放好了？旧房的门别锁。|
|mon.vira.left|还在车旁？算了，就放着吧。|
|mon.main04.title|整备好后，到花棚右侧的发车杆|
|mon.depart.prompt|发车后，这次交接就结束了。没交还的工具、记录和行李会按现在的安排留下。|
|mon.depart.confirm|发车，继续追猎|
|mon.depart.wait|再等等|
|mon.main05.title|突破赛琳的封锁|
|mon.celine.stop|停下，让这辆车先过去。|
|mon.player.stop|维拉还在里面。|
|mon.celine.worked|你也看见了，我是来守路的。|
|mon.celine.strangers|我收了钱，就得守住这条路。|
|mon.player.continue|那你动手吧。|
|mon.celine.defeated|够了……我不拦你了。|
|mon.main06.title|进入礼堂，追上维拉|
|mon.vira.fight|你非要跟到这里？|
|mon.player.fight|你还想带走什么？|
|mon.vira.answer|我没打算告诉你。让开。|
|mon.main07.title|沿原路回装卸庭找玛拉|
|mon.evidence.luggage.home|那只没标签的箱子留在了旧房一侧。|
|mon.evidence.luggage.cart|那只没标签的箱子还在车旁。|
|mon.mara.after|礼堂打成这样，还怎么接货？我得找人把通道清出来。|
|mon.ina.after.return|我先不走。工具刚拿回来。|
|mon.ina.after.keep|找拿着箱子的人修吧。我走了。|
|mon.ruka.after.records|教新人可以，工钱得另算。|
|mon.ruka.after.none|接班的人还没来。我再等一趟。|
|mon.celine.after.helped|我得找玛拉结账。她最好别扣钱。|
|mon.celine.after.other|我跟你没什么可说的。|
|mon.exit.notice|后门通向旧运输线，铁门仍锁着。|
|mon.exit.title|修道院追猎结束|
|mon.closed.side.notice|车已经走了。这次交接结束了。|
|mon.restart.prompt|重新开始本章？当前进度会被替换，你将回到运输站。|
|mon.restart.confirm|重新开始|
|mon.restart.cancel|继续游戏|
|mon.combat.busy|交火中，暂时无法交谈。|
|mon.passage.locked|侧门还锁着。|
|mon.flow.opening.intent|我想问她几句话。|
|mon.flow.entry.cross|穿过门楼，到装卸庭问路|
|mon.flow.route.find|打开通往内庭的路|
|mon.flow.route.choose|选择内庭路线|
|mon.flow.route.lift|带工具到货梯门前松开卡榫|
|mon.flow.route.service|从装卸庭格栅下到泵房|
|mon.flow.celine.job|玛拉。她的货还没交完。|
|mon.flow.celine.cross|借赛琳的掩护穿过钟楼庭院|
|mon.flow.ina.side_door|把工具给我，旁边的侧门我来修。|
|mon.flow.tools.done|工具已交还，维护侧门已开。|
|mon.flow.departure.ready|去花棚右侧的发车杆|
|mon.flow.departure.title|发走最后一车？|
|mon.flow.departure.body|发车后，这次物品交接就结束了。未交还的工具、记录和行李按原安排留下，已开的路仍可通行。|
|mon.flow.departure.tools|工具箱还在你手里。|
|mon.flow.departure.records|维修记录还没交给任何人。|
|mon.flow.departure.luggage|维拉的箱子还没安置。|
|mon.flow.departure.go|发车，继续追猎|
|mon.flow.departure.wait|先回去交接|
|mon.flow.celine.warning|停下。先让车走。|
|mon.flow.chapter.explore|留在修道院|
|mon.flow.chapter.title|返回标题|
|mon.flow.next_region.closed|旧运输线的铁门还锁着。|
|mon.action.lift_repair|货梯卡榫|
|mon.action.maintenance_isolate|泵房隔离杆|
|mon.flow.repair.need|先问伊娜怎么修，再取右侧低处的工具箱。|
|mon.flow.repair.delivered|工具箱已交出。可从装卸庭格栅下到泵房。|
|mon.flow.repair.done|卡榫已松开，货梯门已开。工具箱还在你手里。|
|mon.flow.route.upper|穿过钟楼庭院，向右进入花棚|
|mon.flow.route.lift.choice|修货梯，从上路走|
|mon.flow.route.service.choice|走泵房维护道|
|mon.flow.service.safe|沿泵房右侧的楼梯上到内庭|
|mon.flow.route.other|另一条路仍可走。钟台和档案室可自行探索。|
|mon.flow.luggage.preview|旧房在左边，货车在右边。箱子会留在你选的位置。|
|mon.flow.chapter.records|已找到维修记录。|
|mon.flow.chapter.lift|已修好货梯。|
|mon.flow.chapter.service|已打开泵房维护道。|
|mon.flow.chapter.celine|赛琳还在装卸庭。|
|mon.flow.tutorial.move|{key} / {key2}　移动|
|mon.flow.tutorial.jump|{key}　跳跃|
|mon.flow.tutorial.shoot|{key}　开火，反冲会把你向后推|
|mon.flow.tutorial.reload|{key}　换弹|
|mon.flow.tutorial.claw|{key}　向前爪击|
|mon.flow.tutorial.switch|{key}　切枪，长按查看枪槽|
|mon.flow.tutorial.map|{key}　查看已探索的道路|
|mon.flow.tutorial.drop|{key}　穿过脚下的格栅，走下方楼梯|
|mon.flow.key_space|空格|
|mon.flow.key_mouse_1|鼠标左键|
|mon.flow.key_mouse_2|鼠标右键|
|mon.flow.tutorial.shotgun|{key}　近距离开火|
|mon.flow.tutorial.smg|{key}　空中向下开火可减缓下落|

## 演出短句

|ID|标题|短句|
|---|---|---|
|arrival|猩红修道院||
|stairs|门楼石阶|沿右侧石阶下到装卸庭。|
|first_guard|入口守卫|左侧楼梯可以绕到守卫后方。|
|mara|玛拉||
|vira|维拉||
|cooperation|赛琳的掩护|趁她压住守卫，往前走。|
|route_lift|货梯门已开|穿过钟楼庭院，向右进花棚。|
|route_service|隔离锁已扣住|沿右侧楼梯上到内庭。|
|tools|工具已交接|侧门开了，回程可以抄近路。|
|records|记录已交接|东侧货运门已开。|
|luggage|箱子放好了|继续去花棚右侧。|
|departure|最后一车|整备好后，可以拉下发车杆。|
|celine_duel|赛琳挡住了路|她要让车先走。|
|celine_after|封锁解除|赛琳还活着。维拉在礼堂里。|
|vira_duel|礼堂里的维拉|车还没开出去。|
|vira_after|车停了|回装卸庭找玛拉。|
|return|回到装卸庭||

## 地图地点

|ID|名称|
|---|---|
|region.mon_01|运输站|
|region.mon_02|门楼|
|region.mon_03|装卸庭|
|region.mon_04|门楼上廊|
|region.mon_05|装卸台|
|region.mon_06|货场上廊|
|region.mon_07|货梯口|
|region.mon_08|钟楼庭院|
|region.mon_09|钟台|
|region.mon_10|地下货道|
|region.mon_11|泵房|
|region.mon_12|维护道|
|region.mon_13|档案室|
|region.mon_14|花棚内庭|
|region.mon_15|礼堂前廊|
|region.mon_16|礼堂|

## 审核与接入记录

本轮实际读取项目game-story-workflow、game-narrative及local-adaptation、Narrative Designer模板、game-design-natural-writing-zh、clear-natural-writing和game-ux-restraint。旧工作流中的humanizer要求已被当前项目规则替代，未调用移除的技能。

本稿不新增剧情分支。保留运行ID、占位符、互斥交付和两场战斗结果；对话按角色当前所知写作。接入时逐项核对JSON与本稿，检查选择后果、字形、换行及实际触发顺序。

2026-10-27：以修订后的clear-natural-writing 4.4.0再次通读全部157条章节文字、17段演出及16个地点名。恢复有用的连接、对象和条件，不按20字拆句；保留人物的拒绝和利害冲突，不新增私交、安慰或人格解释。24条章节文字与4段演出作实际调整，其余经复核保留。菜单、系统、HUD与调试设置另见player-text-2026-10-27-review.json及配套说明。
