# 启动、暂停与章节完成界面

用途：系统界面，不新增剧情事实。2026-09-22接入稿，已按natural-writing-zh检查动作与后果。按钮不得烘焙在生成图片中。

| ID | 正文 |
|---|---|
| title | 反冲挽歌 |
| chapter | 猩红修道院 |
| continue | 继续游戏 |
| begin | 开始游戏 |
| restart | 从头开始 |
| quit | 退出游戏 |
| settings | 设置 |
| help | 操作说明 |
| back | 返回 |
| pause | 已暂停 |
| checkpoint | 从检查点重试 |
| title_return | 返回标题 |
| restart_title | 重新开始这一章？ |
| restart_body | 当前章节进度将重新开始。旧存档会保留备份。 |
| confirm | 确认重开 |
| cancel | 取消 |
| completed | 猩红修道院 · 本章完成 |
| completed_body | 你可以继续探索，查看留下的记录，或返回标题。 |
| explore | 继续探索 |
| journal | 查看记录 |
| volume | 主音量 |
| fullscreen | 全屏显示 |
| shake | 镜头震动 |
| retry_save | 重试保存 |
| retry_load | 重试读取存档 |
| settings_failed | 设置未保存。请检查存储空间或写入权限后重试。 |
| settings_load_failed | 设置文件无法读取，暂时使用默认设置。 |
| quit_unsaved_title | 退出前的进度尚未保存 |
| quit_unsaved_body | 退出后，尚未保存的进度将丢失。要直接退出吗？ |
| quit_unsaved | 不保存，退出游戏 |
| on | 开启 |
| off | 关闭 |
| help_body | A / D　移动\nSpace　跳跃　　W　空中修正\n鼠标瞄准　左键射击　R 换弹\n1—6　选择枪槽　滚轮切枪\n短按 Q 切枪，按住 Q 查看枪槽\nV　爪击　　E　交谈或调查\nS　选择下方开放式楼梯或下穿格栅\nM　地图　　J　日志　　Esc　暂停 |

备注：help_body表中的\\n接入为实际换行。设置项必须实际生效；未实现选项不显示。返回标题先尝试保存，失败时保留可见提示，不可宣称保存成功。完成页只在已存在的returned章节完成事实成立后出现，不增加新故事结局。已损坏且无法恢复的存档不允许以“从头开始”静默覆盖。
