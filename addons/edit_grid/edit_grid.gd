#============================================================
#    Edit Grid
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-14 12:10:22
# - version: 4.2
#============================================================
class_name EditGrid
extends Control


### 单元格的值发生改变
#signal cell_value_changed(cell: Vector2i, last_value, current_value)
## 单元格被点击
signal cell_clicked(cell: Vector2i)
## 单元格被双击
signal cell_double_clicked(cell: Vector2i)
## 鼠标经过这个单元格
signal cell_hovered(cell: Vector2i)


@export var panel_border_color : Color = Color.WHITE:
	set(v):
		panel_border_color = v
		queue_redraw()
@export var grid_color : Color = Color.WHITE:
	set(v):
		grid_color = v
		queue_redraw()
@export var grid_line_width : int = 1:
	set(v):
		grid_line_width = v
		queue_redraw()
@export_range(1,100,1,"or_greater") var default_width : int = 90
@export_range(1,100,1,"or_greater") var default_height : int = 40


var _rows : Array = []
var _columns : Array = []
var _highlight_cell : Dictionary = {}
var _data : Dictionary = {}
var _texture_cache : Dictionary = {}
var _custom_column_width : Dictionary = {}
var _custom_row_height : Dictionary = {}


func _init():
	clip_contents = true
	resized.connect(queue_redraw)


func _ready():
	queue_redraw()


var _last_hover_cell := Vector2i(-1, -1)
func _gui_input(event):
	if event is InputEventMouseMotion:
		var cell_coords = get_cell_by_mouse_pos()
		if _last_hover_cell != cell_coords:
			cell_hovered.emit(cell_coords)
			_last_hover_cell = cell_coords
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var cell = get_cell_by_mouse_pos()
			if event.double_click:
				cell_double_clicked.emit(cell)
			else:
				cell_clicked.emit( cell )


func _draw():
	# 行
	_rows.clear()
	var p_row = 0
	while p_row <= size.y:
		draw_line(Vector2(0, p_row), Vector2(size.x, p_row), grid_color, grid_line_width)
		_rows.append(p_row)
		p_row += default_height
	_rows.append(p_row)
	
	# 列
	_columns.clear()
	var p_column = 0
	while p_column <= size.x:
		draw_line(Vector2(p_column, 0), Vector2(p_column, size.y), grid_color, grid_line_width)
		_columns.append(p_column)
		p_column += default_width
	_columns.append(p_column)
	
	# 绘制数据
	for row in _data:
		if row < _rows.size():
			var columns_data = _data[row]
			for column in columns_data:
				if column < _columns.size():
					var value = columns_data[column]
					var cell = Vector2i(column, row)
					if not value is Object:
						value = str(value)
						_draw_text(cell, value)
					elif value is Texture2D:
						_draw_texture(cell, value)
					elif value is Image:
						if not _texture_cache.has(value):
							_texture_cache[value] = ImageTexture.create_from_image(value)
						_draw_texture(cell, _texture_cache[value])
					else:
						printerr("数据类型错误")
	
	draw_rect(Rect2(Vector2(1,1), size), panel_border_color, false, 1)
	
	# 填充鼠标经过的单元格
	for cell in _highlight_cell:
		if cell.x < _columns.size() and cell.y < _rows.size():
			var pos = get_pos_by_cell(cell)
			var end = get_pos_by_cell(cell + Vector2i(1, 1))
			draw_rect(Rect2(pos, end - pos), _highlight_cell[cell], false, grid_line_width + 4)


func _draw_text(cell: Vector2i, text: String):
	var rect = get_cell_rect(cell)
	if rect.size.x < 0 or rect.size.y < 0:
		return
	var font : Font = get_theme_default_font()
	var height = font.get_height()
	draw_string(
		font, rect.position + Vector2(0, height), text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		rect.size.x, 
		get_theme_default_font_size()
	)

func _draw_texture(cell: Vector2i, texture: Texture2D):
	var rect = get_cell_rect(cell)
	rect.size -= Vector2(grid_line_width+1, grid_line_width+1)
	draw_texture_rect(texture, rect, true)

func is_highlight_cell(cell: Vector2i) -> bool:
	return _highlight_cell.has(cell)

func add_highlight_cell(cell: Vector2i, color: Color):
	_highlight_cell[cell] = color
	queue_redraw()

func remove_highlight_cell(cell: Vector2i):
	_highlight_cell.erase(cell)
	queue_redraw()

func get_highlight_cells() -> Array:
	return _highlight_cell.keys()


## 获取上次鼠标悬停位置的单元格
func get_last_hover_cell() -> Vector2i:
	return _last_hover_cell

##清除之前的数据，重新绘制表格的数据。数据以 
##[codeblock]
##data[row][column] = value
##[/codeblock]
##格式传入这个参数。
##[br]数据值的类型只能是 [String], [int], [float], [bool] 等基本数据类型或者 [Texture2D], [Image] 对象类型
func queue_redraw_data(data: Dictionary):
	_data.clear()
	_data.merge(data)
	queue_redraw()

##使用单元格坐标格式的key的数据进行展示数据。数据格式为
##[codeblock]
##data[Vector2i(column, row)] = value
##[/codeblock]
func queue_redraw_data_by_cell_key(data: Dictionary):
	var tmp_data = {}
	var row : int 
	var column : int
	for cell in data:
		column = cell.x
		row = cell.y
		if not tmp_data.has(row):
			tmp_data[row] = {}
		tmp_data[row][column] = data[cell]
	queue_redraw_data(tmp_data)

## 获取这个单元格的矩形大小
func get_cell_rect(cell: Vector2i) -> Rect2:
	var pos = get_pos_by_cell(cell)
	var end = get_pos_by_cell(cell + Vector2i(1, 1))
	return Rect2( pos, end - pos )
	#var rect =  Rect2( pos, end - pos )
	#assert(rect.size.x > 0 or rect.size.y > 0)
	#return rect

## 获取鼠标位置的单元格
func get_cell_by_mouse_pos() -> Vector2i:
	return get_cell_by_pos(get_local_mouse_position())

## 获取这个单元格的位置
func get_pos_by_cell(cell: Vector2i) -> Vector2:
	if cell.x >= 0 and cell.y >= 0 and cell.x < _columns.size() and cell.y < _rows.size():
		return Vector2(_columns[cell.x], _rows[cell.y])
	return Vector2i(-1, -1)

## 获取这个位置的单元格
func get_cell_by_pos(pos: Vector2) -> Vector2i:
	var row_idx : int = -1
	for row in _rows:
		if row > pos.y:
			break
		row_idx += 1
	
	var column_idx : int = -1
	for column in _columns:
		if column > pos.x:
			break
		column_idx += 1
	
	return Vector2i(column_idx, row_idx)

func get_data(column: int, row: int):
	return _data.get(Vector2i(column, row))

func get_data_by_cell(cell: Vector2i):
	if _data.has(cell.y):
		return _data[cell.y].get(cell.x)
	return null

func add_data(column: int, row: int, value):
	if not _data.has(row):
		_data[row] = {}
	#var last_value = _data[row].get(column)
	#if typeof(last_value) != typeof(value) or last_value != value:
		#cell_value_changed.emit(Vector2i(column, row), last_value, value)
	#else:
		#return
	_data[row][column] = value
	queue_redraw()

func add_data_by_cell(cell: Vector2i, value):
	add_data(cell.x, cell.y, value)

