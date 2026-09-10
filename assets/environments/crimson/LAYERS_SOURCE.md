# 夜景与材质源图 v1

生成日期：2026-09-10。使用 Codex 内置 imagegen；工具不提供可核验的模型型号。本轮未调用外部 CLI/API。

保留源图：night_layers_source_v1.png、moon_source_v1.png、materials_source_v1.png。运行时使用裁出的 sky_v3.png、castle_v3.png、moon_v1.png 和九种 *_v1.png 材质。旧 skyline_v2.png 保留作历史来源，主三维场景不再引用。

夜景源图请求为一个两行背景图集：上半为深海军蓝云层天空，不含月亮与建筑；下半为带少量暗红窗光的蓝灰哥特城堡剪影，空处纯品红。生成图为 1536×1024，上下各 512 像素。月亮单独请求：居中、灰蓝陨坑色块、象牙白满月、无外发光、无云、无建筑，纯品红底。两图都要求清晰像素簇和吸血鬼哥特氛围。

材质图集请求：square production pixel art material atlas, exactly 3 by 3 equal square cells without gaps, borders, labels or objects. Flat surface swatches, restrained low contrast Gothic vampire game style. Row1 wrought iron gray scratches / aged brass patina / walnut wood grain. Row2 neutral tan leather book binding subtle horizontal embossed bands / ivory parchment with faded ink marks / beige vertically braided rope fibers. Row3 green leaf veins / crimson rose petal folds / blood red glass broad glints. Each texture fills its full cell. Coarse readable pixel clusters, not noise, no perspective.

拆图工具 tools/prepare_environment_layers.py 保留原尺寸，仅裁切、从材质格内缩 4 像素及去品红色键；不额外绘制内容、不平滑缩放。运行时用 Nearest 和无 mipmap 导入，铁、黄铜、木材使用世界坐标纹理投影。手绘感、色块密度和可读性仍须看实际游戏画面。
