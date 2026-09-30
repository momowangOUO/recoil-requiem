# 玛拉翻账本与维拉收箱动作

2026-09-30。新增两套完整人物动作，不替换莉芙，也不修改 NPC 的原待机、行走和战斗动作。内置 imagegen 生成 `chapter_actions_source_v1.png`，1536×1024 RGBA，三列两行。上排为玛拉低头看账本、翻页、抬眼，下排为维拉俯身扶箱、压下锁扣、站起看向来人。全身稿确认发色、衣装、身体比例和道具接触后，再拆运行帧。没有用平移静态人物模拟动作。

## 来源与拆分

生成原文件：`C:/Users/liyian.andy/.codex/generated_images/01a0f13b-9603-74e0-8b3c-724fef5ca02f/exec-f2b4b021-80a2-43c9-bdba-3920724d7160.png`。参考图为 `npcs_source_v3.png` 左列玛拉及 `../campaign/boss_actions_v2.png` 的维拉。没有指定或声称某个图像模型版本。

运行文件为 `mara_story_v1.png` 与 `vira_story_v1.png`，各384×128，每格128×128。生成图存在两类底噪：alpha 为0但RGB保留棕紫背景，以及轮廓附近少量半透明背景。拆分脚本先将 alpha 小于0.5的像素连同RGB清零，其余设为完全不透明，再按最近邻裁切缩放。运行图只含0和1两档alpha，不保留光晕。源图保持原样；只看四角或 alpha 大于0.5的包围盒不足以验证透明度。

运行 `tools/art/prepare_npc_story_actions.gd` 可重建两张图。玛拉三帧共享 `96/449` 比例，维拉三帧共享 `96/439` 比例；维拉弯身帧保持较矮，不分别归一化。脚底锚点都落在每格 `(64,120)`。准确源裁区与锚点记录在该脚本中，采用实际图像坐标，不假定生成结果精确对齐等分网格。微小的站姿变化来自作者绘制，程序不另加身体位移。

`CampaignNPC.play_story_action("ledger"或"luggage", duration)` 开始一次动作；省略名称时按 NPC 身份选择。`step_story_action(delta)` 供暂停的章节演出推进人物绘制；正常游玩时现有 `_process` 自行推进，调用方不能同时重复推进。动作只暂缓已存在的行走路径，不修改任务事实、世界位置或面向。结束后恢复原待机，下一次正常更新继续原行走路径。

玛拉沿用42逻辑像素身高；维拉沿用现有 boss 第一帧的显示身高，避免换动作时缩小。每人三帧共用一个运行比例，左右朝向沿用原镜像规则。维拉第三帧站起时箱边约有2逻辑像素的作者绘制偏移，这套短动作不提供单独箱体物理动画，不会移动关卡中的碰撞或交互点。

## 完整生成提示词

Production animation sprite atlas for existing Gothic steampunk pixel game. Reference1 identity: ONLY LEFT COLUMN woman Mara with short brown bob, ruby brooch, plum-dark-purple tailored long coat, black lace high neck and corset, silver chains, brown boots, ledger. Reference2 identity: Vira with long dark-violet hair and red bow, wine-red coat gold epaulettes and gold trim, black corset trousers, black boots, ivory gloves. Preserve both women's exact head/body proportions, hairstyles, face identities, colors and wardrobe. DO NOT copy other characters. A NEW atlas, exactly THREE columns and TWO rows, six equal square cells, 1536x1024. TOP ROW exactly three complete full-body animation poses of Mara, facing three-quarter right. 1 looking down holding open ledger at waist, 2 right hand visibly turns ONE cream page while left supports open book, 3 page settled and head/eyes lift toward approaching person, mouth neutral. Feet planted same baseline, same stance, no whole-body bob, no weapons. BOTTOM ROW exactly three complete full-body poses of Vira facing three-quarter right. 1 bent modestly at hips, both gloved hands resting on small rectangular closed dark leather luggage trunk on floor immediately to her right, 2 distinct right hand pressing brass latch shut, left hand bracing lid, 3 fully straightened upright same height/proportions as reference with one hand withdrawn and head looking toward approaching person; the very same closed trunk remains exactly in place throughout all three cells, stable boot placement. Put Vira's sword and pistol away for this noncombat action; do not change costume. All SIX complete women from hair to boot soles fully visible, no cropping. Each row has shared character scale, consistent foot anchor at cell local x230,y465 with stable planted boots; generous transparent margin. Vira third pose is reference upright body height; bending reduces actual head height naturally, do NOT rescale bent frames to fill cell. Both characters compact stylized adult anime women like references, about3.5 heads tall. Clean hard pixel clusters with nearest-neighbor enlarged pixels, limited2-3shades per material, dark outlines, no smooth illustration, blur, antialiasing, shadows, floor scenery, labels, grid, text or borders. GENUINE transparent alpha background, no magenta or checkerboard. Make page movement and hand/trunk interaction clearly different in consecutive frames. Output only this complete six-pose atlas.

## 验证边界

`tests/test_npc_story_actions.gd` 已通过44项检查：三帧载入、非重复绘制、脚底与裁区、正常及暂停时的时钟、世界位置不漂移、行走继续、未知动作拒绝和重载清零。透明度追加检查遍历每一像素，要求alpha为0或1，alpha为0时RGB也为0，不仅检查不透明包围盒。两张运行图的 `process/fix_alpha_border=false`，避免导入重新向透明边缘写入颜色；使用最近邻，无mipmap。

同一测试加 `--capture-npc-story` 在实际 Godot GPU 场景中输出 `artifacts/npc_story_{mara,vira}_{0,1,2}.png`。已逐张检查翻页、按扣与站起帧，人物与未改动莉芙同时出现，640×360原生画面没有棕紫矩形或半透明光晕。这些是明确定位机位的渲染夹具，不是连续通关；完整章节演出衔接及录像由主任务登记。机位改变后先更新角色合成窗口，再暂停，避免拿空建筑画面冒充人物验收。
