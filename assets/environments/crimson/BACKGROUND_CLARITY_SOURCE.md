# 可接近背景清晰度修订，2026-09-30

运行接入：`scripts/rooms/image_monastery_visual.gd`。四幅完整实景概念图、修改前截图和逐字提示词位于 `dev-design/levels/image-led/clarity-20260930/`。温室采用此前已确认的完整五湾立面作为施工参考，再生成单湾生产素材。保留 640×360 世界视口、最近邻采样、原镜头参数、灯光、物理和通路坐标。

## 图像来源

本轮图像均由内置 imagegen 根据本项目已接受美术／实机截图生成，没有引入外部美术素材。

| 项目内文件 | 原始生成文件名 | 参考 |
|---|---|---|
| tower-concept.png | exec-abd3b255-4833-4ca7-adf5-913c18f2ab78.png | tower-before.png、已接受 monastery-concept.png |
| gate-concept.png | exec-67efcea3-2c98-4791-b7ce-c100b0ce31c7.png | gate-before.png |
| hall-concept.png | exec-bd6511a9-1afe-4754-8a91-e7f6de39f4e6.png | hall-before.png |
| archive-concept.png | exec-3b671e7e-11bd-44de-b8e6-6574f77284ab.png | archive-before.png |
| archive_bookshelf_v1.png | exec-a65f7bbd-2dc6-4af0-b013-a6ce016cdc43.png | archive-concept.png |
| garden_close_bay_v1.png | exec-92288910-9ac2-4961-ae4b-67b0f43f2a60.png | 已接受 garden_facade_v2.png、第一版单湾图 |

前五张原文件在 `C:/Users/liyian.andy/.codex/generated_images/01a0f086-172e-7d12-866c-ac1240ba9ec3/`；温室原文件在 `C:/Users/liyian.andy/.codex/generated_images/01a0f1e4-bd62-7043-bda5-e0ac7d3b7ce8/`。温室采用图完整复制为 `dev-design/levels/image-led/clarity-20260930/garden-close-source.png`，其运行副本为 `assets/environments/crimson/garden_close_bay_v1.png`。开发源图由现有导出规则 `dev-design/*` 排除；运行副本参与导出。没有提高视口分辨率、放大源图或锐化旧图来冒充新细节。

书架生产图实际为不透明 1024×1536 PNG，直接复制、无缩放绘改；无损导入，不生成 mipmap。提示词要求七层，产物实际六层。采用检查过的层起点 y=54、274、486、704、922、1144；每层裁区 x=40、宽944、高188。第七层复用第一层。统一比例0.375逻辑像素／源纹素，即2.667源纹素／逻辑像素，每排书面354×70.5。顶层超出原柜顶的部分裁掉。原七块层板仍位于 y=336、416、496、576、656、736、816，厚度不变。书面 z=-1.205，在原层板与后栏后方，替代旧13×42通用贴图书盒。

石墙复用已接受的 `close_facade_bays_v1.png`（2048×768），生成与裁图证据见 `CLOSE_FACADE_SOURCE.md`。盲拱、扶壁裁区分别为(512,0,448,768)、(1536,0,512,768)，礼堂补墙采用(960,0,576,768)。每源像素显示0.5逻辑像素，末列／顶行裁切，不拉伸。新贴面携带实际来源及世界矩形，供回归验证。

## 图与施工对应

| 图中主体 | 运行节点 | 逻辑世界矩形 | 深度与分层 |
|---|---|---|---|
| 开放折返钟梯后石墙 | ClarityTower* | (9216,-1000,784,2776) | z=-2.32；保留开放踏步、后柱、灯和承台 |
| S02上行石阶后的门楼 | ClarityGate* | (1536,-384,1280,1024) | z=-2.36；挖出原窗洞 |
| 活动地板区间后的礼堂下墙 | ClarityHall* | (13472,1040,288,384) | z=-2.12；玻璃后退，洞口独立；无新地板 |
| 档案柜旁墙面 | ClarityArchiveHouse*／Right* | (6336,296,336,584)、(7056,296,72,584) | z=-2.36；在原扶壁／拱后 |
| 档案书面 | ClarityArchiveBooks* | 原柜(6672,296,384,584)以内 | z=-1.205；柜体／层板厚度保留 |
| 温室近处下墙 | ClarityGarden0..4Wall／Edge | x=10000..11832，y≈1031.085..1424 | 墙z=-2.34；玻璃z=-2.395；洞口z=-2.365；原图栏框z=-2.32 |

碰撞、楼梯与路线没有改动。钟塔细节限制在原后方建筑矩形内，开放楼梯的空隙及建筑外天空仍可见。旧完整立面继续提供屋顶和远轮廓，新近景覆盖可接近墙面。

### 温室配准

采用图实际是 **1254×1254**，并非提示词请求的1536×1536；报告和回归均使用实际尺寸。相同源图未经重采样接入，密度约 **3.1643源纹素／逻辑像素**，高于2的要求。

五扇窗沿用 `garden_facade_v2.png` 的既有源矩形：(107,302,331,299)、(514,302,328,299)、(921,302,329,299)、(1328,302,329,299)、(1736,302,329,299)。原整立面源矩形(20,15,2132,681)，世界矩形 x=10000、宽1832、底1424。旧窗口世界位置和尺寸不变，也没有把五湾改成一排重复小窗。

生产图窗口配准为 y=172、高813、x中心627。每扇窗的源宽由原世界宽／统一比例0.3160231602计算，约892..900像素。墙面按相邻原窗中心中点裁切，不横向拉长图稿；上下保持同一比例。两端约18逻辑像素的剩余边墙采用同图 x=8 起的石柱裁区填充。墙、玻璃的实际UV裁区写入节点元数据。

12条直栏框采用原图像素独立前置：上下条(y=172高12、y=970高15)、竖条(x=207、337、452、569、674、782、901、1024；y=394、高576、宽10)、两条横栏(y=647、826，高10)。玻璃网格挖掉相同裁区，避免同一栏条前后重复；洞口沿用现有薄内壁。上方三拱曲线保留在完整玻璃画面上，目前没有把所有曲线花饰逐像素拆成独立厚度。旧完整温室贴面保留在更后方；玻璃、墙面和前框不改变角色遮挡平面。

## 验证与边界

Godot 4.7.2 headless：近景密度／深度／覆盖 **735项通过**；建筑接地 **555项通过**；温室分层 **31项通过**；既有纸片分层 **1997项通过**。网格范围容差允许引擎最小0.00001米厚度；玻璃因挖掉前框条带，包围盒可以略小于原窗矩形。新增回归另核对五扇玻璃的原中心、尺寸和深度。

四个原重点位置与16个区域锚点的六机位截图位于 `artifacts/background_clarity_before/`、`artifacts/background_clarity/`，此前每套120张640×360图片和20张原尺寸六视图已人工检查；这是锚点抽查，不能当作全地图每米均检查过。

`tests/replay_background_clarity.gd` 此前在四处执行960帧连续键盘输入，32项通过：实际横移、物理跳跃、切枪及镜头弹簧／距离变化；只在切换夹具时初始化位置，每段240帧内不重置变换。每处六帧见 `artifacts/background_clarity_motion/`。自动引擎输入回放与人工看图不等于真人试玩。

新石墙采用较小重复模块，尚未逐项复现概念图中的独特高柱、成对巨拱及黄铜管道；档案仍保留原七层高度，未改成产物六层。原结构柱、石阶和木层板仍用既有材质。mon_01大面积暗挡墙仍显重复，mon_11大黄铜罐仍有噪点；这些不是本切片已经修复的内容。温室已补近处下墙与五扇宽窗，顶上原斜屋顶及冠饰仍用旧完整图，远处城堡／天空的雾化是原设计。温室植物与烛光随单湾重复，曲线花饰仍在玻璃图中，这是与完整五湾原图的可见差异。

### 温室实机复核

`tests/test_background_clarity.gd -- --campaign-test --capture --garden-only` 已在GPU完成4个位置×6个镜头距离，共24张原生640×360截图。位置为(10800,1424)、西端(10120,1424)、东端(11720,1424)、抬高机位(10800,1160)。最后一个是检查上檐／三拱接缝的人工机位，不宣称它是可站立平台。每处六图分别为 `artifacts/background_clarity/Garden_six_views.png`、`GardenWest_six_views.png`、`GardenEast_six_views.png`、`GardenUpper_six_views.png`，已全部人工查看。窗格比例、五湾中心和边墙接合可接受，未发现本次新露底。旧斜向大挡墙、顶棚横梁与原图的差异依旧存在。

连续回放新增温室位置与 `--garden-only` 选项，已实际运行240连续帧，8项检查通过、0失败；真实横移、跳跃、三枪切换和镜头距离变化均发生。六个采样帧在 `artifacts/background_clarity_motion/Garden.png`，已人工查看；这不是每帧视频审查。完整五处回放现在为1200帧，本次温室专项只报告实际运行的240帧。

## 温室逐字提示词

第一张生产图没有采用，原文件名 `exec-2dc2ecb1-194f-4fb7-8ced-3582ae99dc86.png`；检查发现窗洞比原窗偏宽，因此生成第二版。两次均用内置 imagegen，背景为不透明，没有外部API调用。

第一张输入参考为完整 `garden_facade_v2.png`：

```text
Use case: stylized-concept. Production game environment asset, not a concept screenshot. The reference is the ACCEPTED five-bay Gothic glasshouse. Create ONE complete lower wall bay, to replace one of those same five wide window bays at higher authored pixel density. Square 1536x1536 PNG, exact frontal orthographic elevation, opaque rectangular asset, tightly fill entire canvas, NO perspective. The reference supplies style and architecture; do not redraw the whole greenhouse. Subject: a single WIDE Gothic greenhouse window bounded by narrow weathered blue-grey masonry piers at left and right, fine aged bronze iron tracery, blue night glass, subdued plants behind lower glass. Window is wide, roughly 1.1 width to height, NOT a narrow tall church window. Its top is three Gothic arches with center circular/quatrefoil tracery exactly like the reference, bottom rectangular panes; all part of ONE broad window, no new separate bays. Composition production coordinates: window opening approx x=180..1356, y=180..1240; side stone piers outside that rectangle; a narrow dark decorative bronze frieze at y=0..180; stone sill at y=1240..1290 and three crisp large stone foundation courses y=1290..1536. No roof, no pediment, no walkway, no objects in front. All edges meet rectangular canvas. Style: actual restrained low-resolution pixel art, sharp deliberate pixel clusters and stair-step contours; modest masonry block shapes, precise two-tone edges, sparse wear; NO photograph grain, NO painterly smoothness, NO blur or haze. Dark blue-grey, desaturated bronze; night glass dark cobalt with faint simple foliage silhouettes, very limited amber warmth. It will be displayed as a ~370x370 logical pixel paper theatre wall behind a 42-pixel character, so background must stay less contrasty than actors. No characters, no typography, no labels, no floor shadow. Opaque full canvas. Reference glass is diffuse but new close-view asset should have deliberately crisp authored edges.
```

第二张以前一张为编辑目标：

```text
Precise production edit of the attached single greenhouse bay. Preserve style, colors, pixel clusters and one wide three-arch window. Deliver 1536 by 1536 or larger square image. Recompose the same bay with THICKER side masonry: the window opening must occupy only x=13.3%..86.7% of canvas and y=12.0%..78.5% of canvas (width 73.4%, height 66.5%, aspect ratio 1.10). Currently window is too wide, 84%; narrow it to those proportions, widen the stone piers. Re-author the arch curves to fit, do not stretch/resample the old image. Keep entire frieze across top 0..12%, window bottom sill at78.5%, foundation below to100%. Crisp deliberate low-resolution pixel art, sparse material colors, no noisy fine speckling, no photoreal grain. Opaque rectangular frontal wall tile, no outside margins, no text. Keep this ONE wide three-part window, no added windows, no new design.
```
