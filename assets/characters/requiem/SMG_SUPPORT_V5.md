# SMG 支撑臂与整圈旋转

2026-09-11。用户验收重点：枪械连续旋转 360° 时肩、肘、腕和握点正常，支撑手心朝画面，后手不能穿到身体前。

## 素材来源

- `smg_whole_fit_v4.png`：初次双姿势工作稿，用户指出袖口、手腕连接不清楚，已否决，不作运行素材。
- `smg_support_source_v4.png`：袖子与关节布局模板，手背朝向不符合最终要求，不作运行素材。
- `smg_whole_fit_v5.png`：重建袖口与前臂连接的整身参考，imagegen `exec-6a569d62-fd5d-42b7-a8d5-aa5467422111`。最终验收依据是实际运行的整圈旋转，而不是单张参考插画。
- `smg_support_source_v5.png`：最终手心朝外的独立左臂，imagegen `exec-1b837fe1-ae88-4693-86b7-f12f1ac43339`，1746×901。
- `smg_left_support_v5.png`：运行贴图，由 tools/prepare_smg_support.py 统一缩至 45%，最近邻采样，不局部拉伸手臂，不用程序重画手掌。旧 v4 运行候选不再加载。

最终生成提示词：

> Finalize the far LEFT support-arm sprite on reference1 canvas for the connected full-body pose in reference2. Preserve reference1 canvas dimensions 1746x901, all sleeve pixels, shoulder/elbow/wrist positions and complete ivory cuff exactly. Edit ONLY hand x965..1200 y430..642: use PALM-FACING anatomy in reference3, cupped left palm with clear thenar pad and one subtle palm crease, FOUR curled fingers at right edge, ONE thumb on lower side. Not knuckle/back-of-fist. Palm center stays x1080 y535, wrist x965 y535, no scaling or translation, short natural digits. Reconstruct the same left support hand that attaches to the visible ivory cuff below the magazine in reference2; no detached wrist. No weapon, magazine, text, labels or extra hands. Use restrained pixel shading matching reference2; simplify excessive crease marks in reference3. Solid #FF00FF background. Final asset must rotate cleanly around unchanged authored wrist anchor.

整身重建要求：保持原角色服装、头身比例和短枪；近侧右手扳机，远侧左肘在腰部外侧可见，酒红前臂连接象牙色袖口再连接掌心，两个手腕保持间隔，禁止孤立手掌贴在弹匣上。先检查水平完整持枪连接，再以运行时角度扫描验证向下和向上姿态。

## 挂点与遮挡

原图挂点：肩 (565,250)、肘 (665,535)、腕 (965,535)、掌心 (1080,535)。运行挂点统一乘 0.45，绘制比例仍为 0.05。SMG 掌心目标由旧的 (12,3.5) 改为瞄准局部 (14.2,3.5)，对准弹匣，不再落到扳机附近。近侧肘挂点下移一个源像素，解决逐度测试发现的微小不可达区。

基础远臂整条在身体后。正常持枪时，support_palm_front 仅补画可以露在枪前的掌面，并通过身体当前帧的真实透明度以及近侧扳机手进行遮挡。换弹禁用前掌补画，整条远臂和手掌回到身体后侧。不能再把整只左掌无条件画到最后。

肘点使用随人物朝向固定的弯曲分支，取消按屏幕 y 方向临时换边的判断。tests/test_arm_rig.gd 按每 1° 检查三把枪、多组装填进度和正上／正下朝向保留区，共 5627 项。tests/capture_aim_sweep.gd 用真实角色绘制连续旋转，记录正常持枪和循环装填；docs/screenshots/aim_360.gif 为 6 秒循环记录，每 3° 保存一帧。

限制：这是实际 GPU 渲染与自动角度扫描，不是人工键鼠试玩。人物越过朝向阈值时仍有设计上的左右翻身；修复目标是翻身前后关节连接与层级正确，不是让纸片人物在深度轴上转身。

交付检查：tools/run_checks.ps1 全部通过；唯一 Windows 输出已覆盖并启动 120 帧，退出码 0，无脚本或着色器错误。SHA-256：2725D2AB1DA7A2F954267B190BEB782DE311725EBB972018DF3AE93DC052E179。本轮账户检查剩余约 36%，完成当前修复后收尾。
