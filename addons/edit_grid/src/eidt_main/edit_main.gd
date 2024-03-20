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


const FILE_FORMAT = "egd" # Edit Grid Data


@onready var menu = %Menu
@onready var edit_grid = %EditGrid
@onready var file_path_label = %FilePathLabel
@onready var save_status_label = %SaveStatusLabel
@onready var prompt: MarginContainer = %prompt

@onready var open_file_dialog: FileDialog = %OpenFileDialog
@onready var save_file_dialog: FileDialog = %SaveFileDialog
@onready var import_file_dialog: FileDialog = %ImportFileDialog
@onready var export_file_dialog: FileDialog = %ExportFileDialog


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
		file_path_label.text = ("null" if _current_file_path == "" else _current_file_path)
var _prompt_tween : Tween
var _undo_redo : UndoRedo = UndoRedo.new()
var _copied_rect : Rect2i = Rect2i() # 复制数据时的矩形位置
var _copied_data : Dictionary = {} # 复制到的数据
var _cut_status : bool = false # 是否在进行剪切。如果为 true，则在粘贴时清除复制的内容


#============================================================
#  内置
#============================================================
func _ready():
	# 文件弹窗
	var filters = [
		"*.%s;%s" % [ FILE_FORMAT, FILE_FORMAT.to_upper() ]
	]
	open_file_dialog.filters = filters
	save_file_dialog.filters = filters
	for dialog in [
		open_file_dialog,
		save_file_dialog,
		export_file_dialog,
		import_file_dialog
	]:
		dialog.size = Vector2i(550, 350)
	
	# 初始化菜单
	menu.init_menu({
		"File": [
			"New", "Open", "-", 
			"Save", "Save As", "-", 
			{ "Export": ["JSON", "CSV"] },
			{ "Import": ["CSV"] }, "-",
			"Print",
		],
		"Edit": [
			"Undo", "Redo", "-",
			"Copy", "Cut", "Paste", "-", "Clear"
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
		"/Edit/Copy": {"ctrl": true, "keycode": KEY_C},
		"/Edit/Cut": {"ctrl": true, "keycode": KEY_X},
		"/Edit/Paste": {"ctrl": true, "keycode": KEY_V},
		"/Edit/Clear": {"keycode": KEY_BACKSPACE},
	})
	menu.set_menu_disabled_by_path("/Edit/Undo", true)
	menu.set_menu_disabled_by_path("/Edit/Redo", true)
	menu.set_menu_disabled_by_path("/Edit/Copy", true)
	menu.set_menu_disabled_by_path("/Edit/Cut", true)
	menu.set_menu_disabled_by_path("/Edit/Paste", true)
	
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
	if _prompt_tween != null:
		_prompt_tween.stop()
	# 显示
	prompt.get_node("Label").text = "  " + text
	create_tween().tween_property(prompt, "modulate:a", 1, 0.2)
	# 延迟隐藏
	_prompt_tween = create_tween()
	_prompt_tween.tween_property(prompt, "modulate:a", 0, 0.2).set_delay(time)


func _reset_variable():
	_cut_status = false
	_copied_rect = Rect2i()
	_copied_data = {}
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
		# TODO 没有保存时处理
		pass
		#return false
		
	return true

func _new_file():
	_reset_variable()
	_current_file_path = ""
	edit_grid._cell_to_box_size_dict = {}
	edit_grid.reset_cell_offset()
	edit_grid.clear_custom_column_width()
	edit_grid.clear_custom_row_height()
	edit_grid.set_grid_data({})
	edit_grid.clear_select_cells()
	_on_edit_grid_selected_cells()

func _export_file(path: String):
	match path.get_extension():
		"csv":
			var data : Dictionary = edit_grid.get_grid_data()
			EditGridUtil.save_data_to_csv(data, path)
			
		"json":
			pass

func _import_file(path: String):
	if FileAccess.file_exists(path):
		match path.get_extension():
			"csv":
				_new_file()
				_current_file_path = path
				var data : Dictionary = EditGridUtil.get_csv_file_data(path)
				edit_grid.set_grid_data(data)
				
			"json":
				pass
		
	else:
		show_prompt(path + "文件不存在！")


func _copy():
	_copied_data = {}
	var rect : Rect2i = edit_grid.get_select_cell_rect()
	rect.position += edit_grid.get_cell_offset()
	_copied_rect = rect
	var value
	for row in range(rect.position.y, rect.end.y + 1):
		var column_data : Dictionary = {}
		for column in range(rect.position.x, rect.end.x + 1):
			value = edit_grid.get_cell_value(Vector2i(column, row))
			if value:
				column_data[column] = value
		if not column_data.is_empty():
			_copied_data[row] = column_data


func _alter_rect_cell(curr_rect: Rect2i, last_rect: Rect2i, data: Dictionary):
	var data_cell : Vector2i
	var cell: Vector2i
	for row in curr_rect.size.y + 1:
		data_cell.y = last_rect.position.y + row
		var row_data : Dictionary = data.get(data_cell.y, {})
		for column in curr_rect.size.x + 1:
			cell = curr_rect.position + Vector2i(column, row)
			data_cell.x = last_rect.position.x + column
			# 粘贴
			edit_grid.add_data(cell.x, cell.y, row_data.get(data_cell.x), false)


#============================================================
#  连接信号
#============================================================
func _on_menu_menu_pressed(idx: int, menu_path: StringName) -> void:
	match menu_path:
		"/File/New":
			if _check_save():
				_new_file()
		
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
		
		"/File/Export/CSV":
			if _check_save():
				export_file_dialog.popup_centered()
		
		"/File/Import/CSV":
			if _check_save():
				import_file_dialog.popup_centered()
		
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
		
		"/Edit/Copy":
			_copy()
			if not _copied_data.is_empty():
				show_prompt("已复制", 0.75)
				print("复制数据：", _copied_data)
		
		"/Edit/Cut":
			if edit_grid.get_select_cell_count() > 0:
				_copy()
				_cut_status = true
		
		"/Edit/Paste":
			if not _copied_data.is_empty():
				# 粘贴选中的区域的数据
				var rect : Rect2i = edit_grid.get_select_cell_rect()
				rect.position += edit_grid.get_cell_offset()
				var selected_data : Dictionary = edit_grid.get_data_by_rect(rect)
				_add_undo_redo(
					"粘贴", 
					_alter_rect_cell.bind(rect, _copied_rect, _copied_data),
					_alter_rect_cell.bind(rect, rect, selected_data),
					true
				)
				# 剪切掉之前的内容
				if _cut_status:
					_alter_rect_cell(_copied_rect, _copied_rect, {})
					_cut_status = false
			
		"/Edit/Clear":
			var rect : Rect2i = edit_grid.get_select_cell_rect()
			rect.position += edit_grid.get_cell_offset()
			var selected_data : Dictionary = edit_grid.get_data_by_rect(rect)
			_add_undo_redo(
				"粘贴", 
				_alter_rect_cell.bind(rect, rect, {}),
				_alter_rect_cell.bind(rect, rect, selected_data),
				true
			)
			
		_:
			print("没有实现功能。菜单路径：", menu_path)


func _add_undo_redo(action_name, do_method: Callable, redo_method: Callable, action : bool = true):
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(do_method)
	_undo_redo.add_undo_method(redo_method)
	_undo_redo.commit_action(action)
	
	menu.set_menu_disabled_by_path("/Edit/Undo", false)


func _on_edit_grid_cell_value_changed(cell: Vector2i, last_value, current_value):
	if last_value == null:
		last_value = ""
	if current_value == null:
		current_value = ""
	if last_value == current_value:
		return
	
	_save_status = false
	_add_undo_redo(
		"alter cell value",
		edit_grid.add_datav.bind(cell, current_value, false),
		edit_grid.add_datav.bind(cell, last_value, false),
		false
	)


func _on_edit_grid_column_width_changed(column: int, last_width: int, width: Variant) -> void:
	_save_status = false
	_add_undo_redo(
		"alter column width",
		edit_grid.add_custom_column_width.bind(column, width, false),
		( # 撤销方法
			edit_grid.remove_custom_column_width.bind(column, false)
			if last_width == -1
			else edit_grid.add_custom_column_width.bind(column, last_width, false)
		),
		false
	)


func _on_edit_grid_row_height_changed(row: int, last_height: int, height: Variant) -> void:
	_save_status = false
	_add_undo_redo(
		"alter row height",
		edit_grid.add_custom_row_height.bind(row, height, false),
		( # 撤销方法
			edit_grid.remove_custom_row_height.bind(row, false)
			if last_height == -1
			else edit_grid.add_custom_row_height.bind(row, last_height, false)
		),
		false
	)


func _on_edit_grid_selected_cells() -> void:
	menu.set_menu_disabled_by_path("/Edit/Copy", edit_grid.get_select_cell_count()==0)
	menu.set_menu_disabled_by_path("/Edit/Cut", edit_grid.get_select_cell_count()==0 )
	menu.set_menu_disabled_by_path("/Edit/Paste", _copied_data.is_empty() or edit_grid.get_select_cell_count()==0 )

