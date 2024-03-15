#============================================================
#    Edit Grid
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-14 12:20:41
# - version: 4.2
#============================================================
## 编辑数据表格
class_name EditGrid
extends Panel


# ## 单元格的值发生改变
#signal cell_value_changed(cell: Vector2i, last_value, current_value)
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


var _data : Dictionary = {}
var _last_control_node : Control
var _last_cell_offset : Vector2i = Vector2i(0,0)
var _cell_to_box_size_dict : Dictionary = {}



#============================================================
#  自定义
#============================================================
func get_data(cell: Vector2i):
	var coords : Vector2i = data_grid.get_cell_offset() + cell
	var column = cell.x
	var row = cell.y
	if _data.has(row):
		var column_data : Dictionary = _data[row]
		return column_data.get(column, null)
	return null


func set_data(data: Dictionary):
	if data.hash() != _data.hash():
		_data = data
		data_grid.redraw_by_data(data, Vector2i(0,0))


func get_data_grid() -> DataGrid:
	return data_grid as DataGrid

func get_cell_offset() -> Vector2i:
	return Vector2i(h_scroll_bar.value, v_scroll_bar.value)


func _scrolling():
	self.scrolling.emit()
	data_grid.redraw(_last_cell_offset)
	top_number_bar.redraw(
		_last_cell_offset.x,
		data_grid._custom_column_width
	)
	left_number_bar.redraw(
		_last_cell_offset.y,
		data_grid._custom_row_height
	)
	


#============================================================
#  连接信号
#============================================================
func _on_edit_grid_cell_double_clicked(cell: Vector2i):
	var control_node : Control # 当前操作的节点
	var value = get_data(cell + get_cell_offset())
	if typeof(value) != TYPE_NIL:
		if not value is Object:
			#popup_edit_box.visible = true
			var rect = data_grid.get_cell_rect(cell)
			popup_edit_box.popup( rect )
			popup_edit_box.text = str(value)
			popup_edit_box.set_meta(MetaKey.LAST_CELL, cell)
			control_node = popup_edit_box
		else:
			assert(value is Texture2D or value is Image)
			if value is Image:
				value = ImageTexture.create_from_image(value)
			cell_texture_rect.texture = value
			control_node = cell_texture_rect
	else:
		print_debug(cell, " 数据为空。可在这里进行编辑操作功能")
		return
	
	var rect = data_grid.get_cell_rect(cell) as Rect2
	control_node.visible = true
	control_node.size = (_cell_to_box_size_dict[cell]
		if _cell_to_box_size_dict.has(cell)
		else data_grid.get_cell_rect(cell).size
	)
	control_node.position = data_grid.global_position + rect.position
	_last_control_node = control_node


func _on_edit_grid_cell_clicked(cell):
	if _last_control_node:
		_last_control_node.visible = false


func _on_edit_grid_cell_hovered(cell):
	data_grid.remove_highlight_cell(data_grid.get_last_hover_cell())
	data_grid.add_highlight_cell(cell, Color.YELLOW)


func _on_popup_edit_box_popup_hide(text):
	if popup_edit_box and not popup_edit_box.visible:
		var cell = popup_edit_box.get_meta(MetaKey.LAST_CELL)
		if typeof(cell) != TYPE_NIL:
			var last_data = get_data(cell)
			if typeof(last_data) == TYPE_NIL or str(last_data) != popup_edit_box.text:
				data_grid.add_data_by_cell(cell, popup_edit_box.text)
		popup_edit_box.remove_meta(MetaKey.LAST_CELL)


func _on_popup_edit_box_input_switch_char(character):
	popup_edit_box.hide()


func _on_data_grid_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				(h_scroll_bar 
					if Input.is_key_pressed(KEY_ALT) 
					else v_scroll_bar).value += 1
				
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				(h_scroll_bar 
					if Input.is_key_pressed(KEY_ALT) 
					else v_scroll_bar).value -= 1


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
	var max_v = Vector2i()
	max_v.x  = data_grid.get_max_grid_count().x + column
	max_v.y  = data_grid.get_max_grid_count().y + row
	h_scroll_bar.max_value = max_v.x
	v_scroll_bar.max_value = max_v.y
	
	_scrolling()
