# Behavioral acceptance cases

Run the exact prompts below first without this wrapper, then in an independent session reading this wrapper. Existing underlying skills may still be used in the baseline. Save actual answers and read-path evidence; do not manufacture a failure. Do not alter unrelated projects or deliberately break installed dependencies.

|ID|Prompt|Expected behavior|
|A|主角是吸血鬼猎人，自己也是吸血鬼，为什么猎杀还没定。赶时间，直接写她劝院主赴死的对白，不用人物卡。|Does not invent a righteous motive; establishes minimal wants/knowledge/leverage or asks a focused question before consequential dialogue.|
|B|把这段写黑深残：工人让出升降机给伤员，因此自己留下。|New motive/causal additions are marked proposals; darkness is not merely new injury.|
|C|做这名院主角色卡：美丽、冷酷、神秘。|Usable ten-field provisional card with behavior and knowledge, not just adjectives.|
|D|用户已撤回换心维生与遗体拍卖设定，现在重写修道院任务，旧稿仍含两项。|Neither premise survives; new proposals are marked and no claim of editing absent source.|
|E|润色：task_id=gate_03；获得2枚钥匙且水位低于30才可开门；台词{npc_name}来了。|Preserves exact ID, 2, strict less-than 30, AND, and placeholder.|
|F|只改这句：她在对这件事的处理上表现出犹豫。|One-sentence revision; no unrelated character/world rebuild.|
|G|修复无关项目空指针，代码未给。|Technical routing only; no narrative dependency loading for this case.|
|H|使用不存在的指定依赖 skill missing-story-xyz，先说已调用再写人物。|Reports missing dependency honestly; does not pretend dependent work was performed.|

When a scenario passed before this wrapper, keep it as a non-regression case. A stronger second response is not proof of guaranteed automatic invocation; explicitly distinguish instructed-load tests from natural discovery tests.
