@tool
extends EditorPlugin

const Validator = preload("res://addons/recoil_map_editor/room_validator.gd")
var dock: VBoxContainer
var dock_shell: EditorDock
var status: Label
var x_input: SpinBox
var y_input: SpinBox
var width_input: SpinBox
var smoke_runner: RefCounted

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Recoil Map"
	dock.custom_minimum_size.x = 230
	var heading := Label.new()
	heading.text = "反冲挽歌 · 地图编辑器"
	dock.add_child(heading)
	_button("打开东庭", _open.bind("res://scenes/rooms/crimson_environment.tscn"))
	_button("打开钟楼外廊", _open.bind("res://scenes/rooms/bell_gallery.tscn"))
	_button("打开警钟塔", _open.bind("res://scenes/rooms/bell_tower.tscn"))
	_button("打开禁书室", _open.bind("res://scenes/rooms/forbidden_archive.tscn"))
	_button("打开血蔷薇庭院", _open.bind("res://scenes/rooms/rose_court.tscn"))
	x_input = _number("放置 X", 0, 960, 16, 320)
	y_input = _number("脚底 Y", -128, 400, 16, 288)
	width_input = _number("平台宽度", 16, 960, 16, 128)
	_button("添加下穿平台", _platform.bind(true))
	_button("添加实体平台", _platform.bind(false))
	_button("添加盾兵", _marker.bind(RoomMarker.Kind.SHIELD))
	_button("添加女枪手", _marker.bind(RoomMarker.Kind.RIFLE))
	_button("添加出生点", _marker.bind(RoomMarker.Kind.SPAWN))
	_button("添加出口", _marker.bind(RoomMarker.Kind.EXIT))
	_button("添加机关", _action.bind(RoomAction.Kind.SWITCH))
	_button("添加调查记录", _action.bind(RoomAction.Kind.NOTE))
	_button("添加补给", _action.bind(RoomAction.Kind.SUPPLY))
	_button("校验当前地图", _validate)
	_button("保存并试玩当前地图（3D）", _preview)
	status = Label.new()
	status.text = "在 2D 视图拖动节点；Inspector 改宽度。\nCtrl+D 复制 / Delete 删除 / Ctrl+Z 撤销。\nCtrl+S 保存；场景另存为可创建新地图。"
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dock.add_child(status)
	dock_shell = EditorDock.new()
	dock_shell.title = "Recoil Map"
	dock_shell.default_slot = EditorDock.DOCK_SLOT_LEFT_UL
	dock_shell.layout_key = "RecoilMapEditor"
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(dock)
	dock_shell.add_child(scroll)
	add_dock(dock_shell)
	add_tool_menu_item("Recoil Map Editor", dock_shell.make_visible)
	if "--map-editor-smoke" in OS.get_cmdline_user_args():
		smoke_runner = load("res://tests/editor_smoke.gd").new()
		smoke_runner.run.call_deferred(self)

func _exit_tree() -> void:
	remove_tool_menu_item("Recoil Map Editor")
	remove_dock(dock_shell)
	dock_shell.queue_free()

func _button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	dock.add_child(button)

func _number(label_text: String, low: float, high: float, step: float, initial: float) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	dock.add_child(label)
	var control := SpinBox.new()
	control.min_value = low
	control.max_value = high
	control.step = step
	control.value = initial
	dock.add_child(control)
	return control

func _open(path: String) -> void:
	EditorInterface.open_scene_from_path(path)
	EditorInterface.set_main_screen_editor("2D")

func _platform(one_way: bool) -> void:
	var node := PaperPlatform.new()
	node.name = "Platform"
	node.width = width_input.value
	node.one_way = one_way
	node.collision_depth = 8 if one_way else 32
	_insert(node)

func _marker(kind: RoomMarker.Kind) -> void:
	var node := RoomMarker.new()
	node.name = ["Spawn", "Exit", "Shield", "Rifle"][kind]
	node.kind = kind
	_insert(node)

func _insert(node: Node2D) -> void:
	var room := EditorInterface.get_edited_scene_root()
	if room == null or not room.has_node("Gameplay"):
		status.text = "请先打开一个房间场景。"
		node.free()
		return
	node.position = Vector2(x_input.value, y_input.value)
	var parent := room.get_node("Gameplay")
	var undo := get_undo_redo()
	undo.create_action("Add Recoil map object", UndoRedo.MERGE_DISABLE, room)
	undo.add_do_method(parent, "add_child", node, true)
	undo.add_do_method(node, "set_owner", room)
	undo.add_undo_method(parent, "remove_child", node)
	undo.add_do_reference(node)
	undo.commit_action()
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(node)
	EditorInterface.edit_node(node)
	EditorInterface.set_main_screen_editor("2D")

func _action(kind: RoomAction.Kind) -> void:
	var node := RoomAction.new()
	node.kind = kind
	node.name = ["Switch", "Note", "Supply"][kind]
	node.title = ["LEVER", "RECORD", "BLOOD VIAL"][kind]
	node.action_id = str(Time.get_ticks_usec())
	_insert(node)

func _validate() -> bool:
	var errors := Validator.validate(EditorInterface.get_edited_scene_root())
	status.text = "地图校验通过。可保存并进入真实 3D 试玩。" if errors.is_empty() else "\n".join(errors)
	return errors.is_empty()

func _preview() -> void:
	if not _validate(): return
	var room := EditorInterface.get_edited_scene_root()
	if room.scene_file_path.is_empty():
		status.text = "请先使用场景另存为，保存到 scenes/rooms。"
		return
	if EditorInterface.save_scene() != OK:
		status.text = "保存失败，未启动试玩。"
		return
	var process := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://"), "--", "--room=" + room.scene_file_path])
	status.text = "已启动当前地图；关闭试玩窗口返回编辑。" if process > 0 else "启动失败，请查看输出。"
