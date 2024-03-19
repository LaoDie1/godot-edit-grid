#============================================================
#    Edit Main
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-17 22:35:08
# - version: 4.2.1
#============================================================
## 主编辑窗口
##
##整体界面场景。对编辑的数据进行保存、加载等
@tool
extends MarginContainer


const FILE_FORMAT = "egd" # Godot Edit Grid Data File


@onready var menu = %Menu
@onready var edit_grid = %EditGrid
@onready var file_path_label = %FilePathLabel
@onready var save_status_label = %SaveStatusLabel
@onready var open_file_dialog: FileDialog = %OpenFileDialog
@onready var save_file_dialog: FileDialog = $SaveFileDialog
@onready var prompt: MarginContainer = %prompt


var _save_status : bool = true:
	set(v):
		if _save_status != v:
			_save_status = v
			save_status_label.text = "Saved" if _save_status else "Not Saved"
			save_status_label.modulate = (
				Color.WHITE if _save_status else Color.ORANGE
			)
			save_status_label.modulate.a = 0.8
var _current_file_path: String = "":
	set(v):
		_current_file_path = v
		file_path_label.text = "null" if _current_file_path == "" else _current_file_path
var _prompt_tween : Tween
var _undo_redo : UndoRedo = UndoRedo.new()



#============================================================
#  内置
#============================================================
func _ready():
	# 文件弹窗
	var filters = [
		"*.%s;%s" % [ FILE_FORMAT, FILE_FORMAT.to_upper() ]
	]
	open_file_dialog.size = Vector2i(500, 350)
	open_file_dialog.filters = filters
	save_file_dialog.size = Vector2i(500, 350)
	save_file_dialog.filters = filters
	
	# 初始化菜单
	menu.init_menu({
		"File": [
			"New", "Open", "-", 
			"Save", "Save As", "-", 
			{
				"Export": ["JSON", "CSV"],
			}, "-",
			"Print",
		],
		"Edit": [
			"Undo", "Redo"
		],
	})
	# 快捷键
	menu.init_shortcut({
		"/File/New": { "ctrl": true, "keycode": KEY_N, },
		"/File/Open": { "ctrl": true, "keycode": KEY_O, },
		"/File/Save": { "ctrl": true, "keycode": KEY_S, },
		"/File/Save As": { "ctrl": true, "shift": true, "keycode": KEY_S, },
		"/Edit/Undo": {"ctrl": true, "keycode": KEY_Z},
		"/Edit/Redo": {"ctrl": true, "shift": true, "keycode": KEY_Z},
	})
	menu.set_menu_disabled_by_path("/Edit/Undo", true)
	menu.set_menu_disabled_by_path("/Edit/Redo", true)
	
	prompt.modulate.a = 0
	
	_undo_redo.version_changed.connect(func():
		self._save_status = false
	)



#============================================================
#  自定义
#============================================================
## 保存文件
func save_file(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		_save_status = true
	else:
		push_error("打开文件出现错误")


## 打开文件
func open_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_var()
	push_error("打开文件出现错误")
	return {}


## 显示提示信息
func show_prompt(text: String, time: float = 2.0):
	if _prompt_tween != null and not is_instance_valid(_prompt_tween):
		_prompt_tween.stop()
	# 显示
	prompt.get_node("Label").text = "  " + text
	create_tween().tween_property(prompt, "modulate:a", 1, 0.2)
	# 延迟隐藏
	_prompt_tween = create_tween()
	_prompt_tween.tween_property(prompt, "modulate:a", 0, 0.2).set_delay(time)


func _reset_variable():
	_undo_redo.clear_history(false)
	_save_status = true
	menu.set_menu_disabled_by_path("/Edit/Undo", true)
	menu.set_menu_disabled_by_path("/Edit/Redo", true)


func _open_grid_data(path: String):
	var file_data = open_file(path)
	if file_data:
		edit_grid.reset_cell_offset()
		edit_grid.set_config_data(file_data["config"])
		edit_grid.set_grid_data(file_data["data"])
		_reset_variable()
		_current_file_path = path

func _save_grid_data(path: String):
	var file_data : Dictionary = {}
	file_data["config"] = edit_grid.get_config_data()
	file_data["data"] = edit_grid.get_grid_data()
	save_file(path, file_data)
	_current_file_path = path
	_reset_variable()
	show_prompt("已保存文件: " + path)

func _save_as():
	save_file_dialog.popup_centered()

func _check_save() -> bool:
	if not _save_status:
		# 没有保存时
		pass
		# TODO 写功能
		#return false
		
	return true



#============================================================
#  连接信号
#============================================================
func _on_menu_menu_pressed(idx: int, menu_path: StringName) -> void:
	match menu_path:
		"/File/New":
			if _check_save():
				_reset_variable()
				_current_file_path = ""
				edit_grid.reset_cell_offset()
				edit_grid.clear_custom_column_width()
				edit_grid.clear_custom_row_height()
				edit_grid.set_grid_data({})
		
		"/File/Open":
			if _check_save():
				open_file_dialog.popup_centered()
		
		"/File/Save":
			if _current_file_path == "":
				_save_as()
			else:
				if not _save_status:
					_save_grid_data(_current_file_path)
		
		"/File/Save As":
			_save_as()
		
		"/File/Print":
			print("打印数据：", edit_grid.get_grid_data())
		
		"/Edit/Undo":
			_undo_redo.undo()
			menu.set_menu_disabled_by_path("/Edit/Undo", not _undo_redo.has_undo())
			menu.set_menu_disabled_by_path("/Edit/Redo", not _undo_redo.has_redo())
			
		"/Edit/Redo":
			_undo_redo.redo()
			menu.set_menu_disabled_by_path("/Edit/Undo", not _undo_redo.has_undo())
			menu.set_menu_disabled_by_path("/Edit/Redo", not _undo_redo.has_redo())
		
		_:
			print("没有实现功能。菜单路径：", menu_path)


func _add_undo_redo(action_name, do_method: Callable, redo_method: Callable):
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(do_method)
	_undo_redo.add_undo_method(redo_method)
	_undo_redo.commit_action(false)
	
	menu.set_menu_disabled_by_path("/Edit/Undo", not _undo_redo.has_undo() )
	print(action_name)


func _on_edit_grid_cell_value_changed(cell: Vector2i, last_value, current_value):
	if last_value == null:
		last_value = ""
	if current_value == null:
		current_value = ""
	if last_value == current_value:
		return
	
	_save_status = false
	_add_undo_redo(
		"修改单元格的值",
		edit_grid.add_datav.bind(cell, current_value, false),
		edit_grid.add_datav.bind(cell, last_value, false)
	)


func _on_edit_grid_column_width_changed(column: int, last_width: int, width: Variant) -> void:
	_save_status = false
	var undo : Callable = (
		edit_grid.remove_custom_column_width.bind(column, false)
		if last_width == -1
		else edit_grid.add_custom_column_width.bind(column, last_width, false)
	)
	_add_undo_redo(
		"修改列宽",
		edit_grid.add_custom_column_width.bind(column, width, false),
		( # 撤销方法
			edit_grid.remove_custom_column_width.bind(column, false)
			if last_width == -1
			else edit_grid.add_custom_column_width.bind(column, last_width, false)
		),
	)


func _on_edit_grid_row_height_changed(row: int, last_height: int, height: Variant) -> void:
	_save_status = false
	_add_undo_redo(
		"修改行高",
		edit_grid.add_custom_row_height.bind(row, height, false),
		( # 撤销方法
			edit_grid.remove_custom_row_height.bind(row, false)
			if last_height == -1
			else edit_grid.add_custom_row_height.bind(row, last_height, false)
		),
	)

