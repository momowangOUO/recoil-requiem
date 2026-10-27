# 修道院场景精修素材来源

2026-10-16。以下十项素材使用本次会话内置 image_gen 补制，保存了实际输出尺寸、alpha裁区、原始输出ID和SHA256。完整提示词见 `dev-design/levels/rebuild/polish-prompts.json`；机器可读来源为同目录 `polish-assets.json`。均为真实RGBA透明图，不使用色键底，不依赖Codex缓存目录运行。

|文件|实际尺寸|不透明主体裁区 x,y,w,h|运行用途|
|---|---|---|---|
|rebuild_stained_glass_v1.png|1099×1431|164,12,771,1397|礼堂独立彩窗，置于真实框台后方|
|rebuild_saint_v1.png|753×2089|97,106,552,1877|礼堂与钟楼雕像，配独立凹龛、基座及纸边|
|rebuild_reredos_v1.png|841×1870|111,72,619,1708|祭坛背饰，独立受光并投影|
|rebuild_red_crown_v1.png|1649×954|34,129,1576,680|红树树冠，置于枝干前方|
|rebuild_tree_branches_v1.png|1138×1382|41,111,1077,1159|枝干，根部落在真实花槽上|
|rebuild_ivy_v1.png|868×1811|221,50,445,1691|前后不同深度的攀藤，保留轮廓空隙|
|rebuild_service_door_v1.png|914×1721|69,69,776,1598|货场门正面，配真实门框和内凹侧壁|
|rebuild_crate_face_v1.png|1448×1086|141,83,1166,918|货箱正面，3D体积、厚度和承托单独生成|
|rebuild_rose_shrub_v1.png|1484×1060|43,71,1408,909|恢复原图花丛，根部落在真实种植槽内|
|rebuild_lantern_v1.png|887×1774|202,187,483,1350|恢复原图可见主灯，独立挂架与真实暖光源同位|

像素簇、轮廓和材质在正常游玩镜头中检查，未对游戏截图做锐化或修图。导入为无损、无mipmap、无缩减，运行nearest采样。素材按不透明裁区保持原比例接入，三维厚度和道路不烘焙到画片里。

沿用用户已确认的修道院原图与项目现有近景作为构图、材质和角色尺度依据；本轮未下载第三方素材。来源是用户提供的参考及本次生成，不额外宣称未核查的第三方许可或生成结果的排他权。

档案室复用 `archive_bookshelf_v1.png`，其原有来源见 `BACKGROUND_CLARITY_SOURCE.md`。花槽面复用 `rebuild_garden_near.png` 的裁区(277,674,174,56)，不重复声明为本轮新生成；门楼石拱及其原始来源保留。角色、敌人和武器源图未修改。

实际节点的纹理、裁区、世界矩形、Z深度、受光和投影属性记录在 `artifacts/monastery-polish-20261016/final/rebuild_details.json`。该文件由实际运行包导出。

本机运行版本为Godot 4.7.2.stable.official.ed1daf0bf。Sprite3D按alpha discard保持纸片轮廓，近景实色画片受灯光并投影；彩窗和灯内玻璃保持独立明暗。接口依据：[官方SpriteBase3D文档](https://docs.godotengine.org/en/latest/classes/class_spritebase3d.html)。最终效果以本轮运行包截图和连续运动录像为准。
