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
## 发生滚动
signal scrolling()


const MetaKey = {
	LAST_CELL = "_last_cell",
}


@onready var data_grid : DataGrid = %DataGrid
@onready var cell_texture_rect = $CellTextureRect
@onready var popup_edit_box = $PopupEditBox
@onready var v_scroll_bar = %VScrollBar
@onready var h_scroll_bar = %HScrollBar
@onready var top_number_bar = %top_number_bar
@onready var left_number_bar = %left_number_bar


var _grid_data : Dictionary = {}
var _last_control_node : Control
var _last_cell_offset : Vector2i = Vector2i(0,0)
var _cell_to_box_size_dict : Dictionary = {}
var _last_clicked_pos : Vector2 = Vector2()
var _last_clicked_cell : Vector2i = Vector2i()
var _last_clicked_cell_rect : Rect2 = Rect2()


#============================================================
#  自定义
#============================================================
func _scrolling():
	# 表格正在滚动
	h_scroll_bar.max_value = h_scroll_bar.value + 10
	v_scroll_bar.max_value = v_scroll_bar.value + 10
	
	popup_edit_box.hide()
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


func add_data(column: int, row: int, value):
	if not _grid_data.has(row):
		_grid_data[row] = {}
	var last_value = _grid_data[row].get(column)
	_grid_data[row][column] = value
	self.cell_value_changed.emit(Vector2i(column, row), last_value, value)
	data_grid.redraw_by_data(_grid_data)

func add_datav(cell: Vector2i, value):
	add_data(cell.x, cell.y, value)

func remove_data(column: int, row: int) -> bool:
	if _grid_data.has(row):
		if _grid_data[row].erase(column):
			self.cell_value_changed.emit(Vector2i(column, row), _grid_data[row][column], null)
			return true
	return false

func remove_datav(cell: Vector2i) -> bool:
	return remove_data(cell.x, cell.y)

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


func add_custom_column_width(column: int, width: float):
	data_grid.add_custom_column_width(column, width)

func add_custom_row_height(row: int, height: float):
	data_grid.add_custom_row_height(row, height)



#============================================================
#  连接信号
#============================================================
func _on_edit_grid_cell_double_clicked(cell: Vector2i):
	var control_node : Control # 当前操作的节点
	var value = get_cell_value(cell + get_cell_offset())
	var rect = data_grid.get_cell_rect(cell) as Rect2
	rect.position += data_grid.global_position
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
			control_node = cell_texture_rect
		
	else:
		#print_debug(cell, " 数据为空。在这里进行编写操作功能")
		#return
		popup_edit_box.popup( rect )
		popup_edit_box.text = ""
		popup_edit_box.set_meta(MetaKey.LAST_CELL, cell + get_cell_offset())
		control_node = popup_edit_box
	
	# 设置显示到的位置
	var real_cell = cell + get_cell_offset()
	control_node.visible = true
	control_node.size = (_cell_to_box_size_dict[real_cell]
		if _cell_to_box_size_dict.has(real_cell)
		else data_grid.get_cell_rect(cell).size
	)
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
			if typeof(last_data) == TYPE_NIL or str(last_data) != popup_edit_box.text:
				add_datav(cell, popup_edit_box.text)
		popup_edit_box.remove_meta(MetaKey.LAST_CELL)


func _on_popup_edit_box_input_switch_char(character):
	popup_edit_box.hide()


func _on_data_grid_gui_input(event):
	if event is InputEventMouseButton:
		if not event.pressed:
			# 网格滚动
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				(h_scroll_bar 
					if Input.is_key_pressed(KEY_ALT) 
					else v_scroll_bar).value += 1
				
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				(h_scroll_bar 
					if Input.is_key_pressed(KEY_ALT) 
					else v_scroll_bar).value -= 1
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_last_clicked_pos = get_global_mouse_position()
				_last_clicked_cell = data_grid.get_cell_by_mouse_pos() + get_cell_offset()
				_last_clicked_cell_rect = data_grid.get_cell_rect( data_grid.get_cell_by_mouse_pos() )
		
	elif event is InputEventMouseMotion:
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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
			
		else:
			
			# 进行拖拽自定义行高列宽
			if data_grid.mouse_default_cursor_shape != Control.CURSOR_ARROW:
				match data_grid.mouse_default_cursor_shape:
					Control.CURSOR_HSIZE:
						var mouse_offset = get_global_mouse_position() - _last_clicked_pos
						var column_width = _last_clicked_cell_rect.size.x + mouse_offset.x
						data_grid.add_custom_column_width(_last_clicked_cell.x, column_width)
						
					Control.CURSOR_VSIZE:
						var mouse_offset = get_global_mouse_position() - _last_clicked_pos
						var row_height = _last_clicked_cell_rect.size.y + mouse_offset.y
						data_grid.add_custom_row_height(_last_clicked_cell.y, row_height)


func _value_changed(value):
	var cell_offset = get_cell_offset()
	if _last_cell_offset != cell_offset:
		if _last_control_node:
			_last_control_node.hide()
		
		_last_cell_offset = cell_offset
		_scrolling()


func _on_popup_edit_box_box_size_changed(box_size):
	if popup_edit_box and popup_edit_box.has_meta(MetaKey.LAST_CELL):
		var cell : Vector2i = popup_edit_box.get_meta(MetaKey.LAST_CELL)
		_cell_to_box_size_dict[cell] = box_size


func _on_data_grid_cell_number_changed(column:int, row:int):
	#var max_v = Vector2i(
		#data_grid.get_max_cell().x + column,
		#data_grid.get_max_cell().y + row
	#)
	#h_scroll_bar.max_value = max_v.x
	#v_scroll_bar.max_value = max_v.y
	_scrolling()

