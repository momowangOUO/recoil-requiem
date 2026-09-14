# 修道院对白与交互正式接入稿

依据 dev-design/narrative/STORY_REVIEW.md。状态：2026-09-14 用户批准事件线与对白，作为正式接入依据。所有角色均在本章初识。

表中条件是作者说明，不直接显示；事实条件需在接入时映射到同名状态。只出现当前场景可见或此前获知的信息。选项不代表善恶分数。

## 入口与目标

|ID|条件／说话人|文字|
|mon.main01.title|追踪目标|进入修道院外庭|
|mon.main01.hint|主线未完成|从装卸入口进入外庭。|
|mon.mara.hello|初见／玛拉|前门不让带枪。你从哪儿进来的？|
|mon.player.entry|回应／莉芙|下面。货道还开着。|
|mon.mara.ask|玛拉|找谁？|
|mon.player.target|莉芙|维拉。|
|mon.mara.target|玛拉|她在货梯那边。要走的人了，东西倒是一件都不肯少带。|
|mon.mara.repeat|再次交谈／玛拉|货梯往里走。别碰贴了封条的箱子。|
|mon.main02.title|入口信息已取得|找到货梯另一端的维拉|
|mon.vira.hello|货梯初见／维拉|等这一趟过去。你站那儿挡着门。|
|mon.player.hunt|莉芙|我不是来取货的。我来找你。|
|mon.vira.recognize|维拉|猎人？|
|mon.player.confirm|莉芙|嗯。|
|mon.vira.reply|维拉|那你等着。我先把东西装上去。|
|mon.player.luggage|莉芙|你打算都带走？|
|mon.vira.luggage|维拉|还没想好。别替我扔。|

## 两翼合作

|ID|条件／说话人|文字|
|mon.main03.title|维拉已离开货梯|寻找通往内院的路|
|mon.main03.hint|追踪提示|钟台和维护道都能绕进内院。|
|mon.ina.hello|初见／伊娜|借工具？先说拿去做什么。|
|mon.player.tools|莉芙|货梯卡住了。|
|mon.ina.tools|伊娜|箱子在里面。拿到以后先给我看一眼，别随便用。|
|mon.ina.repeat|尚未取回工具／伊娜|灰色的铁箱，提手断了一边。|
|mon.ruka.hello|初见／鲁卡|退到黄线后面。门没落稳。|
|mon.player.route|莉芙|这门开了能到内院吗？|
|mon.ruka.route|鲁卡|能。你要赶路，就走侧面的楼梯。我不保证下一趟什么时候来。|
|mon.celine.hello|初次共同交火／赛琳|你管楼梯。我看着上面。|
|mon.celine.cover|主角接近退路／赛琳|过去吧，这里我来。|
|mon.player.return|玩家替赛琳打开退路／莉芙|门开了。往左走。|
|mon.celine.return|赛琳|看见了。你先别挡在门口。|

## 工具支线

|ID|条件／说话人|文字|
|mon.tools.title|支线|找到伊娜的工具箱|
|mon.tools.inspect|读工具箱标签|箱盖写着“伊娜”，封条上却列入了仓库资产。|
|mon.tools.return.choice|持有工具箱|把箱子交还伊娜。|
|mon.tools.keep.choice|持有工具箱且交接处可用|把箱子留在交接处。|
|mon.tools.later.choice|未作决定|先带着箱子离开。|
|mon.ina.returned|工具交还／伊娜|是我的。还少一把扳手……算了，先修货梯。|
|mon.ina.withheld|得知工具留给玛拉／伊娜|你看见箱子上的名字了吧？那就没什么好说的了。|
|mon.mara.tools|工具留在交接处／玛拉|放这儿。仓库侧门可以走了，我让人把锁打开。|
|mon.tools.returned.notice|交还结果|伊娜正在修理维护入口。|
|mon.tools.kept.notice|留下结果|仓库侧门已打开。|

## 维修记录支线

|ID|条件／说话人|文字|
|mon.records.title|支线|找到闸门的维修记录|
|mon.records.note|档案走廊原文|右侧摇柄有空行程，转到底才算落锁。上次更换轴套后仍有偏斜，下一任值守先来看一趟，别照旧图操作。|
|mon.records.ruka.choice|拿到记录|把记录交给鲁卡。|
|mon.records.mara.choice|拿到记录|把记录交给玛拉。|
|mon.records.keep.choice|拿到记录|暂时保留记录。|
|mon.ruka.records|交给鲁卡／鲁卡|连这些都搬走了？我就说找不到。给我吧。|
|mon.mara.records|交给玛拉／玛拉|原来改了这么多。让鲁卡来一趟，新人看图学不会。|
|mon.records.read.notice|只阅读|已记下闸门的维护方式。|

## 行李支线

|ID|条件／说话人|文字|
|mon.luggage.title|支线|核对维拉留下的行李|
|mon.luggage.tag|调查无标签箱|箱子没有标签，锁扣已经打开。里面是几套旧衣服和用过的日用品。|
|mon.vira.request|再次接触且未发车／维拉|那箱没有标签的，放回楼上吧。我不带了。|
|mon.luggage.return.choice|已知请求|把无标签的箱子退回旧房。|
|mon.luggage.leave.choice|已知请求|让箱子留在原来的装卸位置。|
|mon.luggage.defer.choice|已知请求|先查看其他行李。|
|mon.vira.returned|已退回／维拉|放好了？门不用锁。|
|mon.vira.left|箱子仍在／维拉|还在那儿？那就算了，别再搬。|

## 最后发车

|ID|条件／说话人|文字|
|mon.main04.title|已达内庭|找到维拉的发车位置|
|mon.depart.prompt|首次准备进入礼堂|货车即将离开。继续追猎后，未交接的工具和行李将按现有安排处理。|
|mon.depart.confirm|玩家选择|继续追猎。|
|mon.depart.wait|玩家选择|返回内庭。|
|mon.main05.title|继续追猎后的目标|突破赛琳的封锁|
|mon.celine.stop|赛琳守住交接线|让车过去。这里是我接的工作。|
|mon.player.stop|莉芙|我要上去。|
|mon.celine.worked|此前有共同掩护／赛琳|刚才我替你守过楼梯。现在你也退一步。|
|mon.celine.strangers|此前未共同掩护／赛琳|我先说清楚，再往前我就开枪。|
|mon.player.continue|开始突破／莉芙|那你得拦住我。|
|mon.celine.defeated|精英战败但存活／赛琳|走吧。别又让我替你看着后面。|
|mon.main06.title|突破交接线|追上维拉|
|mon.vira.fight|礼堂相遇／维拉|你一直跟到这儿，是想听我求你？|
|mon.player.fight|莉芙|我想看看你会怎么办。|
|mon.vira.answer|维拉|那就站远点。|

## 结果与回访

维拉死亡后不播放解释临终行为的独白。先留出动作和环境声，让玩家看见货车已经停下。以下文字只描述可观察事实。

|ID|条件／说话人|文字|
|mon.main07.title|追猎结束|回到外庭|
|mon.evidence.luggage.home|无标签箱已退回|旧房里留下了那只没有标签的箱子。|
|mon.evidence.luggage.cart|箱子未搬走|货车旁还放着那只没有标签的箱子。|
|mon.mara.after|回访玛拉|礼堂得修。你走之前，把通往外面的门留下，别再弄坏了。|
|mon.ina.after.return|已归还工具／伊娜|我先留几天。东西都在这儿，换个地方还得重新找。|
|mon.ina.after.keep|工具留给玛拉／伊娜|我要走了。箱子在谁手里，你找谁修。|
|mon.ruka.after.records|记录已交付任一方／鲁卡|他们要我带新人。价钱还没说好。|
|mon.ruka.after.none|未交付记录／鲁卡|没人来接班。我再等一趟。|
|mon.celine.after.helped|有合作经历／赛琳|下次见面，先说你要做什么。我不想再猜。|
|mon.celine.after.other|无合作经历／赛琳|我在等人。没什么要跟你说的。|
|mon.exit.notice|打开城市连接|后门通往旧运输线。|
|mon.closed.side.notice|发车时尚未交付的支线|货车已经发走，这次交接无法继续。已找到的记录仍可查看。|

## 接入约束

同一交付只能选一个结果；“暂时保留”不关闭任务。重复交谈读取当前状态，不再触发奖励。未调查标签不显示关于箱子内容的回访记录。精英战结束到返回外庭之间，赛琳的位置由同一世界状态决定。

本稿已按角色知识、明确主语和具体动作顺读。文本 ID、条件和姓名在润色时保持不变。正式接入还须将引擎实际读取的文字导出，与本稿逐项核对；已通过 test_campaign_session.gd 逐项核对运行JSON与本稿；新增界面文案沿用同一核对入口。

## 运行界面补充（不改变故事事实）

|ID|条件／用途|文字|
|mon.restart.prompt|F9 重新开始确认|重新开始会清除当前章节进度，回到运输站。要继续吗？|
|mon.restart.confirm|确认按钮|重新开始|
|mon.restart.cancel|取消按钮|保留进度，继续游戏|
|mon.combat.busy|交火中尝试长对话|先脱离交火，再交谈。|
|mon.passage.locked|未开放货运通道|这条货道还没开放。|
