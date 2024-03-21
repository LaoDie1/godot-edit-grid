#============================================================
#    Edit Grid
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-14 12:20:41
# - version: 4.2
#============================================================
## 编辑数据表格
##
##双击单元格进行编辑。通过 [method set_data] 方法或者 [method add_data] 方法向表格中添加数据。
##[br]鼠标滚轮上下滚动数据，Alt+鼠标滚轮进行左右滚动
##[br]Alt+Enter 进行文本换行
@tool
class_name EditGrid
extends Panel


## 单元格的值发生改变
signal cell_value_changed(cell: Vector2i, last_value, current_value)
## 网格发生滚动
signal scrolling()
## 行高发生改变
signal column_width_changed(column: int, last_width: int, width: int)
## 列宽发生改变
signal row_height_changed(row: int, last_height: int, height: int)
## 已移除列宽
signal column_width_removed(column: int)
## 已移除行高
signal row_height_removed(column: int)
## 选中单元格
signal selected_cells()
## 弹窗菜单被点击
signal popup_menu_clicked(item_name: String)


const MetaKey = {
	LAST_CELL = "_last_cell",
}


@onready var data_grid : DataGrid = %DataGrid
@onready var cell_texture_rect = $CellTextureRect
@onready var popup_edit_box = %PopupEditBox
@onready var v_scroll_bar = %VScrollBar
@onready var h_scroll_bar = %HScrollBar
@onready var top_number_bar = %top_number_bar
@onready var left_number_bar = %left_number_bar
@onready var grid_popup_menu: PopupMenu = %GridPopupMenu


var _last_control_node : Control
var _last_clicked_pos : Vector2 = Vector2()
var _last_clicked_cell : Vector2i = Vector2i() # 上次点击的实际的网格
var _last_clicked_cell_rect : Rect2 = Rect2()

var _grid_data : Dictionary = {}
var _last_cell_offset : Vector2i = Vector2i(0,0)
var _cell_to_box_size_dict : Dictionary = {} # 编辑时的网格大小
var _drag_cell_line_status : bool = false # 拖拽网格大小
var _selecting_cells_status : bool = false: # 是否正在选中网格
	set(v):
		if _selecting_cells_status != v:
			_selecting_cells_status = v
			self.selected_cells.emit()


#============================================================
#  内置
#============================================================
func _ready() -> void:
	grid_popup_menu.clear()
	grid_popup_menu.add_item("Copy")
	grid_popup_menu.add_item("Cut")
	grid_popup_menu.add_item("Paste")
	grid_popup_menu.add_separator()
	grid_popup_menu.add_item("Clear")



#============================================================
#  自定义
#============================================================
func _update():
	# 表格正在滚动
	h_scroll_bar.max_value = h_scroll_bar.value + 10
	v_scroll_bar.max_value = v_scroll_bar.value + 10
	
	data_grid.redraw(_last_cell_offset)
	top_number_bar.redraw(
		_last_cell_offset.x,
		data_grid._custom_column_width
	)
	left_number_bar.redraw(
		_last_cell_offset.y,
		data_grid._custom_row_height
	)
	self.scrolling.emit()


# 更新当前位置的鼠标光标。如果在网格线上，则改变为箭头效果
func _update_grid_cursor_shape() -> CursorShape:
	var cell = data_grid.get_last_hover_cell()
	var rect = data_grid.get_cell_rect(cell)
	var mouse_pos = data_grid.get_local_mouse_position()
	var diff = (rect.end - mouse_pos).abs()
	const MAX_DIST = 8
	if diff.x < MAX_DIST:
		data_grid.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	elif diff.y < MAX_DIST:
		data_grid.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	else:
		data_grid.mouse_default_cursor_shape = Control.CURSOR_ARROW
	return data_grid.mouse_default_cursor_shape


## 重新设置表格偏移
func reset_cell_offset():
	_last_cell_offset = Vector2i(0, 0)
	h_scroll_bar.value = 0
	v_scroll_bar.value = 0


## 获取配置数据
func get_config_data() -> Dictionary:
	var data : Dictionary = {}
	#data["_cell_to_box_size_dict"] = _cell_to_box_size_dict
	
	data["__data_grid"] = {
		"_custom_column_width": data_grid._custom_column_width,
		"_custom_row_height": data_grid._custom_row_height,
	}
	return data


## 设置配置数据
func set_config_data(data: Dictionary):
	for key in data:
		if key in self:
			set(key, data[key])
	var data_grid_data : Dictionary = data["__data_grid"]
	for key in data_grid_data:
		if key in data_grid:
			data_grid.set(key, data_grid_data[key])


## 获取这个单元格上的数据
func get_cell_value(cell: Vector2i):
	var coords : Vector2i = data_grid.get_cell_offset() + cell
	var column = cell.x
	var row = cell.y
	if _grid_data.has(row):
		var column_data : Dictionary = _grid_data[row]
		return column_data.get(column, null)
	return null


## 获取当前表格数据
func get_grid_data() -> Dictionary:
	return _grid_data


## 数据格式详见：[method DataGrid.redraw_by_data] 方法中的描述
func set_grid_data(data: Dictionary):
	if hash(_grid_data) != hash(data):
		_grid_data.clear()
		for row in data:
			_grid_data[row] = {}
			_grid_data[row].merge(data[row])
		data_grid.redraw_by_data(_grid_data, Vector2i(0,0))


##使用单元格坐标格式的key的数据进行展示数据。数据格式为
##[codeblock]
##{
##   Vector2i(column, row): value,
##   Vector2i(column, row): value,
##   Vector2i(column, row): value,
##}
##[/codeblock]
func set_grid_datav(data: Dictionary) -> void:
	var tmp_data = {}
	var row : int 
	var column : int
	for cell in data:
		column = cell.x
		row = cell.y
		if not tmp_data.has(row):
			tmp_data[row] = {}
		tmp_data[row][column] = data[cell]
	set_grid_data(tmp_data)

func get_data_grid_node() -> DataGrid:
	return data_grid as DataGrid

## 单元格偏移值。也就是滚动条滚动的值
func get_cell_offset() -> Vector2i:
	return Vector2i(h_scroll_bar.value, v_scroll_bar.value)


func add_data(column: int, row: int, value, emit_change_signal: bool = true):
	if typeof(value) == TYPE_NIL or value == "":
		remove_data(column, row, emit_change_signal)
		data_grid.queue_redraw()
		return
	
	if not _grid_data.has(row):
		_grid_data[row] = {}
	var last_value = _grid_data[row].get(column)
	if typeof(last_value) != typeof(value) or last_value != value:
		_grid_data[row][column] = value
		if emit_change_signal:
			self.cell_value_changed.emit(Vector2i(column, row), last_value, value)
		data_grid.redraw_by_data(_grid_data)


func add_datav(cell: Vector2i, value, emit_change_signal: bool = true):
	add_data(cell.x, cell.y, value, emit_change_signal)


func remove_data(column: int, row: int, emit_change_signal: bool = true) -> bool:
	if _grid_data.has(row):
		var last_value = _grid_data[row].get(column)
		if _grid_data[row].erase(column):
			if _grid_data[row].is_empty():
				_grid_data.erase(row)
			if emit_change_signal:
				self.cell_value_changed.emit(Vector2i(column, row), last_value, null)
			return true
	return false

func remove_datav(cell: Vector2i, emit_change_signal: bool = true) -> bool:
	return remove_data(cell.x, cell.y, emit_change_signal)


##设置自定义列宽。数据格式:
##{
##  column: width,
##  column: width,
##}
func set_custom_column_width(data: Dictionary):
	data_grid.set_custom_column_width(data)

##设置自定义行高。数据格式:
##{
##  row: height,
##  row: height,
##}
func set_custom_row_height(data: Dictionary):
	data_grid.set_custom_row_height(data)


func add_custom_column_width(column: int, width: float, emit_change_signal: bool = true):
	var last_width : int = data_grid._custom_column_width.get(column, -1)
	if last_width != width:
		data_grid.add_custom_column_width(column, width)
		if emit_change_signal:
			self.column_width_changed.emit(column, -1, width)

func add_custom_row_height(row: int, height: float, emit_change_signal: bool = true):
	var last_height : int = data_grid._custom_row_height.get(row, -1)
	if last_height != height:
		data_grid.add_custom_row_height(row, height)
		if emit_change_signal:
			self.row_height_changed.emit(row, -1, height)

func remove_custom_column_width(column: int, emit_remove_signal: bool = true) -> bool:
	var r = data_grid.remove_custom_column_width(column)
	if r and emit_remove_signal:
		self.column_width_removed.emit(column)
	return r

func remove_custom_row_height(row: int, emit_remove_signal: bool = true) -> bool:
	var r = data_grid.remove_custom_row_height(row)
	if r and emit_remove_signal:
		self.row_height_removed.emit(row)
	return r

func clear_custom_column_width(emit_remove_signal: bool = false) -> void:
	if not data_grid._custom_column_width.is_empty():
		if emit_remove_signal:
			for column in data_grid._custom_column_width:
				self.column_width_removed.emit(column)
		data_grid._custom_column_width.clear()
		data_grid.queue_redraw()

func clear_custom_row_height(emit_remove_signal: bool = false) -> void:
	if not data_grid._custom_row_height.is_empty():
		if emit_remove_signal:
			for column in data_grid._custom_row_height:
				self.row_height_removed.emit(column)
		data_grid._custom_row_height.clear()
		data_grid.queue_redraw()

## 返回实际的数据位置，已计算的偏移值
func get_select_cell_rect() -> Rect2i:
	return data_grid._last_selected_cells_rect as Rect2i

func clear_select_cells():
	data_grid.clear_select_cells()

func get_select_cell_count() -> int:
	return data_grid.get_select_cell_count()

func get_data_by_rect(rect: Rect2i) -> Dictionary:
	var data : Dictionary = {}
	for row in range(rect.position.y, rect.end.y + 1):
		if _grid_data.has(row):
			var column_data : Dictionary = {}
			for column in range(rect.position.x, rect.end.x + 1):
				# 粘贴
				if _grid_data[row].has(column):
					column_data[column] = _grid_data[row][column]
			if not column_data.is_empty():
				data[row] = column_data
	return data

func set_grid_menu_disabled(item_name: String, disabled: bool):
	for id in grid_popup_menu.item_count:
		if grid_popup_menu.get_item_text(id) == item_name:
			grid_popup_menu.set_item_disabled(id, disabled)
			break


#============================================================
#  连接信号
#============================================================
func _on_edit_grid_cell_double_clicked(cell: Vector2i): 
	var real_cell : Vector2i = cell + get_cell_offset()
	var control_node : Control # 当前操作的节点
	var rect : Rect2 = data_grid.get_cell_rect(cell) as Rect2
	rect.position += data_grid.global_position
	rect.size = (_cell_to_box_size_dict[real_cell]
		if _cell_to_box_size_dict.has(real_cell)
		else data_grid.get_cell_rect(cell).size
	)
	var value = get_cell_value(cell + get_cell_offset())
	if typeof(value) != TYPE_NIL:
		if not value is Object:
			popup_edit_box.popup( rect )
			popup_edit_box.text = str(value)
			popup_edit_box.set_meta(MetaKey.LAST_CELL, cell + get_cell_offset())
			control_node = popup_edit_box
			
		else:
			assert(value is Texture2D or value is Image)
			if value is Image:
				value = ImageTexture.create_from_image(value)
			cell_texture_rect.texture = value
			cell_texture_rect.size = rect.size
			control_node = cell_texture_rect
		
	else:
		#print_debug(cell, " 数据为空。在这里进行编写操作功能")
		#return
		popup_edit_box.popup( rect )
		popup_edit_box.text = ""
		popup_edit_box.set_meta(MetaKey.LAST_CELL, cell + get_cell_offset())
		control_node = popup_edit_box
	
	# 设置显示到的位置
	control_node.visible = true
	control_node.global_position = rect.position
	_last_control_node = control_node


func _on_edit_grid_cell_clicked(cell):
	if _last_control_node:
		_last_control_node.visible = false


func _on_popup_edit_box_popup_hide(text):
	if popup_edit_box and not popup_edit_box.visible:
		var cell = popup_edit_box.get_meta(MetaKey.LAST_CELL)
		if typeof(cell) != TYPE_NIL:
			var last_data = get_cell_value(cell)
			if typeof(last_data) == TYPE_NIL or str(last_data) != popup_edit_box.get_text():
				add_datav(cell, popup_edit_box.get_text())
		popup_edit_box.remove_meta(MetaKey.LAST_CELL)


func _on_popup_edit_box_input_switch_char(character):
	popup_edit_box.hide()


func _on_data_grid_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# 按下鼠标按键
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_last_clicked_pos = data_grid.get_local_mouse_position()
					_last_clicked_cell = data_grid.get_cell_by_mouse_pos() + get_cell_offset()
					_last_clicked_cell_rect = data_grid.get_cell_rect( data_grid.get_cell_by_mouse_pos() )
					# 拖拽线条
					_drag_cell_line_status = (
						_update_grid_cursor_shape() in [
							Control.CURSOR_VSIZE,
							Control.CURSOR_HSIZE,
						]
					)
					# 选中多个网格
					data_grid.clear_select_cells()
					_selecting_cells_status = not _drag_cell_line_status
				
				MOUSE_BUTTON_RIGHT:
					# 右键弹窗
					var cell = data_grid.get_cell_by_mouse_pos() + get_cell_offset()
					if not data_grid._selected_cells.has(cell):
						data_grid.clear_select_cells()
						data_grid.add_select_cellv(cell)
						data_grid._last_selected_cells_rect = Rect2i(cell, Vector2i(0, 0))
					grid_popup_menu.position = get_global_mouse_position()
					grid_popup_menu.popup()
					self.selected_cells.emit()
		
		else:
			# 松开鼠标按键
			match event.button_index:
				MOUSE_BUTTON_WHEEL_DOWN:
					(h_scroll_bar 
					if Input.is_key_pressed(KEY_ALT) 
					else v_scroll_bar).value += 1
				
				MOUSE_BUTTON_WHEEL_UP:
					(h_scroll_bar 
					if Input.is_key_pressed(KEY_ALT) 
					else v_scroll_bar).value -= 1
				
				MOUSE_BUTTON_LEFT:
					_selecting_cells_status = false
					
					if _drag_cell_line_status:
						# 上次如果拖拽了，则发出信号
						var curr_rect : Rect2 = data_grid.get_cell_rect(_last_clicked_cell)
						var diff_pos : Vector2 = curr_rect.position - _last_clicked_cell_rect.position
						var diff_size : Vector2 = curr_rect.size - _last_clicked_cell_rect.size
						if diff_size == Vector2(0, 0):
							diff_size = diff_pos
						
						if diff_size.x != 0:
							column_width_changed.emit( _last_clicked_cell.x, _last_clicked_cell_rect.size.x, curr_rect.size.x)
						if diff_size.y != 0:
							row_height_changed.emit( _last_clicked_cell.y, _last_clicked_cell_rect.size.y, curr_rect.size.y)
						_drag_cell_line_status = false
					
			
	elif event is InputEventMouseMotion:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_grid_cursor_shape()
			
		else:
			if _selecting_cells_status:
				# 选中网格
				data_grid.add_select_cells(_last_clicked_cell, data_grid.get_cell_by_mouse_pos() + get_cell_offset() )
			
			# 进行拖拽自定义行高列宽
			if _drag_cell_line_status:
				match data_grid.mouse_default_cursor_shape:
					Control.CURSOR_HSIZE:
						var mouse_offset : Vector2 = data_grid.get_local_mouse_position() - _last_clicked_pos
						var column_width : int = _last_clicked_cell_rect.size.x + mouse_offset.x
						add_custom_column_width(_last_clicked_cell.x, column_width, false)
						
					Control.CURSOR_VSIZE:
						var mouse_offset : Vector2 = data_grid.get_local_mouse_position() - _last_clicked_pos
						var row_height : int = _last_clicked_cell_rect.size.y + mouse_offset.y
						add_custom_row_height(_last_clicked_cell.y, row_height, false)


func _value_changed(value):
	var cell_offset = get_cell_offset()
	if _last_cell_offset != cell_offset:
		if _last_control_node:
			_last_control_node.hide()
		
		_last_cell_offset = cell_offset
		_update()
		popup_edit_box.hide()


func _on_popup_edit_box_box_size_changed(box_size):
	if popup_edit_box and popup_edit_box.has_meta(MetaKey.LAST_CELL):
		var cell : Vector2i = popup_edit_box.get_meta(MetaKey.LAST_CELL)
		_cell_to_box_size_dict[cell] = box_size


func _on_data_grid_cell_number_changed(column:int, row:int):
	_update()
	popup_edit_box.hide()


func _on_data_grid_draw_finished() -> void:
	_update()


func _on_grid_popup_menu_id_pressed(id: int) -> void:
	var item_name : String = grid_popup_menu.get_item_text(id)
	self.popup_menu_clicked.emit(item_name)
