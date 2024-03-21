#============================================================
#    Data Grid
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-14 12:10:22
# - version: 4.2
#============================================================
## 数据展示表格
##
##通过调用 [method redraw_by_data] 方法向表格中绘制数据
@tool
class_name DataGrid
extends Control


## 单元格被点击
signal cell_clicked(cell: Vector2i)
## 单元格被双击
signal cell_double_clicked(cell: Vector2i)
## 鼠标经过这个单元格
signal cell_hovered(cell: Vector2i)
## 网格数量大小发生改变
signal cell_number_changed(column:int, row: int)
## 准备绘制
signal ready_draw()
## 将要绘制数据
signal will_draw(data: DrawData)
## 绘制已完成
signal draw_finished()


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
@export_range(1,100,1,"or_greater") var default_width : int = 90:
	set(v):
		default_width = v
		queue_redraw()
@export_range(1,100,1,"or_greater") var default_height : int = 40:
	set(v):
		default_height = v
		queue_redraw()
@export var text_color : Color = Color(1, 1, 1, 1):
	set(v):
		text_color = v
		queue_redraw()
@export var selecte_cell_color : Color = Color.CORNFLOWER_BLUE:
	set(v):
		selecte_cell_color = v
		queue_redraw()


var _rows_pos : Array = [] # 每个行所在的像素位置
var _columns_pos : Array = [] # 每个列所在的像素位置
var _last_cell_number : Vector2i = Vector2i(0, 0) # 单元格数量发生改变
var _data : Dictionary = {} # 绘制的数据
var _texture_cache : Dictionary = {} # 显示的图片的缓存
var _max_cell : Vector2i = Vector2i(0, 0) # 最大行列位置
var _cell_offset: Vector2i = Vector2i(0, 0) # 绘制的数据坐标偏移值
var _last_hover_cell : Vector2i = Vector2i(-1, -1) # 鼠标经过到的单元格

var _custom_column_width : Dictionary = {} # 自定义某个列宽
var _custom_row_height : Dictionary = {} # 自定义某个行高
var _selected_cells : Dictionary = {} # 选中的单元格
var _last_selected_cells_rect : Rect2i = Rect2i(-1, -1, 0, 0) # 选中的网格范围（没有计算偏移）



#============================================================
#  内置
#============================================================
func _init():
	clip_contents = true
	resized.connect(queue_redraw)


func _ready():
	queue_redraw()


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
	var column_row_number = Vector2i(0, 0)
	# 列
	_columns_pos.clear()
	var p_custom_column_idx : int = _cell_offset.x
	var p_column : int = 0
	while p_column <= size.x:
		_columns_pos.append(p_column)
		draw_line(Vector2(p_column, 0), Vector2(p_column, size.y), grid_color, grid_line_width)
		p_column += _custom_column_width.get(p_custom_column_idx, default_width)
		p_custom_column_idx += 1
	_columns_pos.append(p_column)
	column_row_number.x = _columns_pos.size()
	
	# 行
	_rows_pos.clear()
	var p_custom_row_idx : int = _cell_offset.y
	var p_row : int = 0
	while p_row <= size.y:
		_rows_pos.append(p_row)
		draw_line(Vector2(0, p_row), Vector2(size.x, p_row), grid_color, grid_line_width)
		p_row += _custom_row_height.get(p_custom_row_idx, default_height)
		p_custom_row_idx += 1
	_rows_pos.append(p_row)
	column_row_number.y = _rows_pos.size()
	
	# 显示的行列数发生改变
	if _last_cell_number != column_row_number:
		_last_cell_number = column_row_number
		self.cell_number_changed.emit(_last_cell_number.x, _last_cell_number.y)
	
	self.ready_draw.emit()
	
	# 绘制每个网格上的数据
	var data_cell : Vector2i = Vector2i(0, 0) # 数据所在的实际单元格
	for row in _rows_pos.size()-1:
		data_cell.y = row + _cell_offset.y
		if _data.has(data_cell.y):
			var columns_data : Dictionary = _data[data_cell.y]
			for column in _columns_pos.size()-1:
				data_cell.x = column + _cell_offset.x
				if columns_data.has(data_cell.x):
					var draw_data : DrawData = DrawData.new()
					draw_data.cell = Vector2i(column, row)
					draw_data.value = columns_data[data_cell.x]
					self.will_draw.emit(draw_data)
					# 进行绘制
					_draw_data(draw_data)
	
	self.draw_finished.emit()
	
	# 绘制边框
	draw_rect(Rect2(Vector2(1,1), size), panel_border_color, false, 1)
	
	# 选中的单元格
	for row in _rows_pos.size()-1:
		var cell = Vector2i()
		cell.y = row
		for column in _columns_pos.size()-1:
			cell.x = column
			if _selected_cells.has(cell + get_cell_offset()):
				var rect : Rect2i = get_cell_rect(cell)
				draw_rect( rect, selecte_cell_color, false, grid_line_width + 2)


#============================================================
#  自定义
#============================================================
func _draw_data(draw_data: DrawData):
	if draw_data.enabled:
		if not draw_data.value is Object:
			draw_data.value = str(draw_data.value)
			_draw_text(draw_data.cell, draw_data.value)
		elif draw_data.value is Texture2D:
			_draw_texture(draw_data.cell, draw_data.value)
		elif draw_data.value is Image:
			if not _texture_cache.has(draw_data.value):
				_texture_cache[draw_data.value] = ImageTexture.create_from_image(draw_data.value)
			_draw_texture(draw_data.cell, _texture_cache[draw_data.value])
		else:
			printerr("数据类型错误")


func _draw_text(cell: Vector2i, text: String):
	var rect = get_cell_rect(cell)
	if rect.size.x < 0 or rect.size.y < 0:
		return
	var font : Font = get_theme_default_font()
	var height : float = font.get_height()
	var max_line : int = floori(rect.size.y / height)
	draw_multiline_string(
		font, 
		rect.position + Vector2(0, height), 
		text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		rect.size.x, 
		get_theme_default_font_size(),
		max_line,
		text_color
	)

func _draw_texture(cell: Vector2i, texture: Texture2D):
	var rect = get_cell_rect(cell)
	var image_size = texture.get_size()
	rect.size.x = min(rect.size.x, image_size.x)
	rect.size.y = min(rect.size.y, image_size.y)
	rect.size -= Vector2(1, 1)
	draw_texture_rect(texture, rect, true)


## 展示的数据偏移位置
func get_cell_offset() -> Vector2i:
	return _cell_offset

## 获取上次鼠标悬停位置的单元格。这个是没有偏移值的
func get_last_hover_cell() -> Vector2i:
	return _last_hover_cell

## 获取最大单元格位置
func get_max_cell() -> Vector2i:
	return _max_cell

## 获取网格最大数量
func get_max_cell_number() -> Vector2i:
	return Vector2i(_columns_pos.size(), _rows_pos.size())

## 获取列宽
func get_column_width(column: int):
	return _custom_column_width.get(column, default_width)

## 获取行高
func get_row_height(row: int):
	return _custom_row_height.get(row, default_height)


## 重新绘制网格
func redraw(cell_offset: Vector2i = Vector2i(-1, -1)):
	if cell_offset != Vector2i(-1,-1) and _cell_offset != cell_offset:
		_cell_offset = cell_offset
		queue_redraw()


##清除之前的数据，重新绘制表格的数据。数据以 
##[codeblock]
##{
##   row: {
##     column: value,
##     column: value,
##     column: value,
##   },
##   row: {
##     column: value,
##     column: value,
##   },
##}
##[/codeblock]
##格式传入这个参数。
##[br]数据值的类型只能是 [String], [int], [float], [bool] 等基本数据类型或者 [Texture2D], [Image] 对象类型
func redraw_by_data(
	data: Dictionary, 
	cell_offset: Vector2i = Vector2i(-1,-1),
) -> void:
	if _data != data:
		_data = data
		for row in data:
			if _max_cell.y < row:
				_max_cell.y = max(_max_cell.y, row)
			for column in data[row]:
				if _max_cell.x < column:
					_max_cell.x = max(_max_cell.x, column)
	redraw(cell_offset)
	queue_redraw()


## 获取这个单元格的矩形大小。这个 cell 不能是偏移的值
func get_cell_rect(cell: Vector2i) -> Rect2:
	var pos = get_pos_by_cell(cell)
	var end = get_pos_by_cell(cell + Vector2i(1, 1))
	return Rect2( pos, end - pos )

## 获取鼠标位置的单元格
func get_cell_by_mouse_pos() -> Vector2i:
	return get_cell_by_pos(get_local_mouse_position())

## 获取这个单元格的位置
func get_pos_by_cell(cell: Vector2i) -> Vector2:
	if is_in_view(cell):
		return Vector2(_columns_pos[cell.x], _rows_pos[cell.y])
	return Vector2(-1, -1)

## 获取这个位置的单元格
func get_cell_by_pos(pos: Vector2) -> Vector2i:
	var column_idx : int = -1
	if pos.x > 0:
		for column in _columns_pos:
			if column > pos.x:
				break
			column_idx += 1
	
	var row_idx : int = -1
	if pos.y > 0:
		for row in _rows_pos:
			if row > pos.y:
				break
			row_idx += 1
	
	return Vector2i(column_idx, row_idx)

## 是否在视线可见范围内
func is_in_view(cell: Vector2i) -> bool:
	return cell.x >= 0 \
		and cell.y >= 0 \
		and cell.x < _columns_pos.size() \
		and cell.y < _rows_pos.size()


## 设置自定义列宽
func set_custom_column_width(data: Dictionary):
	if hash(_custom_column_width) != hash(data):
		_custom_column_width.clear()
		_custom_column_width.merge(data)
		queue_redraw()

## 设置自定义行高
func set_custom_row_height(data: Dictionary):
	if hash(_custom_row_height) != hash(data):
		_custom_row_height.clear()
		_custom_row_height.merge(data)
		queue_redraw()
 
func add_custom_column_width(column: int, width: float):
	_custom_column_width[column] = max(16, width)
	queue_redraw()

func add_custom_row_height(row: int, height: float):
	_custom_row_height[row] = max(16, height)
	queue_redraw()

func remove_custom_column_width(column: int) -> bool:
	var r : bool = _custom_column_width.erase(column)
	if r:
		queue_redraw()
	return r

func remove_custom_row_height(row: int) -> bool:
	var r : bool = _custom_row_height.erase(row)
	if r:
		queue_redraw()
	return r

func add_select_cell(column: int, row: int):
	add_select_cellv(Vector2i(column, row))

func add_select_cellv(cell: Vector2i):
	_selected_cells[cell] = null
	queue_redraw()

func remove_select_cell(column: int, row: int):
	remove_select_cellv(Vector2i(column, row))

func remove_select_cellv(cell: Vector2i):
	_selected_cells.erase(cell)


func add_select_cells(begin: Vector2i, end: Vector2i) -> bool:
	var tmp = begin
	begin.x = min(begin.x, end.x)
	begin.y = min(begin.y, end.y)
	end.x = max(tmp.x, end.x)
	end.y = max(tmp.y, end.y)
	var rect : Rect2i = Rect2i(begin, end - begin)
	if _last_selected_cells_rect != rect:
		_selected_cells.clear()
		_last_selected_cells_rect = rect
		for column in range(begin.x, end.x + 1):
			for row in range(begin.y, end.y + 1):
				_selected_cells[Vector2i(column, row)] = null
		queue_redraw()
		return true
	return false

func clear_select_cells() -> void:
	if not _selected_cells.is_empty():
		_last_selected_cells_rect = Rect2i(-1, -1, 0, 0)
		_selected_cells.clear()
		queue_redraw()

## 获取选中的表格
func get_select_cells() -> Array:
	return _selected_cells.keys()

func get_select_cell_count() -> int:
	return _selected_cells.size()

