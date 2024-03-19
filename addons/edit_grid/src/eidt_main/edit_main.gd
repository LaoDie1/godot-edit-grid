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
var _current_file_path: String:
	set(v):
		_current_file_path = v
		file_path_label.text = str(_current_file_path)
var _prompt_tween : Tween


#============================================================
#  内置
#============================================================
func _ready():
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
	})
	# 快捷键
	menu.init_shortcut({
		"/File/New": { "ctrl": true, "keycode": KEY_N, },
		"/File/Open": { "ctrl": true, "keycode": KEY_O, },
		"/File/Save": { "ctrl": true, "keycode": KEY_S, },
		"/File/Save As": { "ctrl": true, "shift": true, "keycode": KEY_S, },
	})
	
	prompt.modulate.a = 0



#============================================================
#  自定义
#============================================================
func save_file(path: String, data):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		_save_status = true
	else:
		push_error("打开文件出现错误")


func open_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_var()
	push_error("打开文件出现错误")
	return {}


func show_prompt(text: String, time: float = 3.0):
	if _prompt_tween != null and not is_instance_valid(_prompt_tween):
		_prompt_tween.stop()
	# 显示
	prompt.get_node("Label").text = "  " + text
	create_tween().tween_property(prompt, "modulate:a", 1, 0.2)
	# 延迟隐藏
	_prompt_tween = create_tween()
	_prompt_tween.tween_property(prompt, "modulate:a", 0, 0.2).set_delay(time)


func _open_grid_data(path: String):
	var file_data = open_file(path)
	if file_data:
		edit_grid.set_config_data(file_data["config"])
		edit_grid.set_grid_data(file_data["data"])
		_current_file_path = path

func _save_grid_data(path: String):
	var file_data : Dictionary = {}
	file_data["config"] = edit_grid.get_config_data()
	file_data["data"] = edit_grid.get_grid_data()
	save_file(path, file_data)
	_current_file_path = path
	show_prompt("已保存文件: " + path)

func _save_as():
	save_file_dialog.popup_centered()

func _check_save() -> bool:
	if not _save_status:
		# 没有保存时
		
		return false
	return true



#============================================================
#  连接信号
#============================================================
func _on_menu_menu_pressed(idx: int, menu_path: StringName) -> void:
	match menu_path:
		"/File/New":
			if _check_save():
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
			_save_status = true
			print("打印数据：", edit_grid.get_grid_data())
		
		_:
			print("没有实现功能。菜单路径：", menu_path)


func _on_edit_grid_cell_value_changed(cell, last_value, current_value):
	_save_status = false

func _on_edit_grid_column_width_row_height_changed() -> void:
	_save_status = false
