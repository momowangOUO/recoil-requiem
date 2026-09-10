# 猩红修道院文本接入稿

依据 natural-writing-zh（GitHub 6737999e8411460405c43c74e7bb18298bebfaa9）。先独立改写并顺读，再映射到现有房间节点。正文中的叙述均为授权世界观创作；任务提示仅描述已实现的目标。每个节点 ID 后的 title / description 对应场景原字段，房间根字段为 room_title / objective_hint。

## bell_tower.room_title
目标：bell_tower.tscn 根节点
~~~~text
猩红修道院 / 警钟塔
~~~~

## bell_tower.objective_hint
条件：本房目标尚未完成
~~~~text
登上钟台，拉下制动杆
~~~~

## bell_tower.BellRope.title
条件：靠近制动杆且站稳
~~~~text
拉下制动杆
~~~~

## bell_tower.BellRope.description
条件：机关激活
~~~~text
警钟已停，回程桥已放下。
~~~~

## bell_tower.TowerRecord.title
~~~~text
守钟人的交班纸
~~~~

## bell_tower.TowerRecord.description
文体：守卫留下的工作记录
~~~~text
发现闯入者，立即鸣钟。今夜不得停钟。

禁书室的门锁和钟架共用拉索。需要进门取巡更册时，先拉下制动杆。
~~~~

## bell_tower.TowerSupply.title
~~~~text
血瓶 · 恢复2格生命
~~~~

## bell_tower.TowerSupply.description
~~~~text
已饮用血瓶，生命恢复。
~~~~

## forbidden_archive.room_title
~~~~text
猩红修道院 / 禁书室
~~~~

## forbidden_archive.objective_hint
~~~~text
寻找转运名单
~~~~

## forbidden_archive.TransferLedger.title
~~~~text
被涂改的转运名单
~~~~

## forbidden_archive.TransferLedger.description
文体：转运簿原文及页边记号。旧教堂送药人的去向写在簿上，避免无依据地让主角认出编号。
~~~~text
第七车：旧教堂送药人一名，随身药箱一只。
已转入内院，原名另册保管。

下面几页只剩药材编号。页边盖着血蔷薇印，印章下写着：转运门须在两侧水闸开启后通行。
~~~~

## forbidden_archive.HiddenLetter.title
~~~~text
没有寄出的信
~~~~

## forbidden_archive.HiddenLetter.description
文体：写给姐姐的私人信件。与抹去姓名的主线相连，不承担通关指令。
~~~~text
姐姐：
我把你的名字又写了一遍，藏在最上面的书架上。她们收走了名册，我怕再过几天，连我也只会叫你的编号。

拾到这封信的人：请把它送到旧教堂。信封里的药签，是我姐姐留下的。
~~~~

## forbidden_archive.ArchiveSupply.title
~~~~text
血瓶 · 恢复2格生命
~~~~

## forbidden_archive.ArchiveSupply.description
~~~~text
已饮用血瓶，生命恢复。
~~~~

## rose_court.room_title
~~~~text
猩红修道院 / 血蔷薇庭院
~~~~

## rose_court.objective_hint
~~~~text
开启两侧水闸，前往转运门
~~~~

## rose_court.WestSluice.title
~~~~text
扳动西侧水闸
~~~~

## rose_court.WestSluice.description
~~~~text
西段步道已放下。
~~~~

## rose_court.EastSluice.title
~~~~text
扳动东侧水闸
~~~~

## rose_court.EastSluice.description
~~~~text
东段步道已放下。
~~~~

## rose_court.CanalLetter.title
~~~~text
渠底的姓名
~~~~

## rose_court.CanalLetter.description
文体：渠壁姓名的抄录，载体是可阅读的纸页。
~~~~text
纸上抄着渠壁的姓名，后面记有转运车次。最后一页只写了两句话：

「还醒着的人留在白银病房。
别让她们把你送进礼堂。」
~~~~

## rose_court.CanalSupply.title
~~~~text
血瓶 · 恢复2格生命
~~~~

## rose_court.CanalSupply.description
~~~~text
已饮用血瓶，生命恢复。
~~~~

## system.exit_open
~~~~text
通路已打开，前往出口
~~~~

## system.health_full
~~~~text
生命已满，血瓶留在这里。
~~~~

## system.complete
~~~~text
转运门已打开 · 本次样段结束
~~~~
