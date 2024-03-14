#============================================================
#    Example
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-14 12:20:41
# - version: 4.2
#============================================================
extends Panel

const MetaKey = {
	LAST_CELL = "_last_cell",
}

@onready var edit_grid = $EditGrid
@onready var cell_text_edit = $CellTextEdit
@onready var cell_texture_rect = $CellTextureRect

var last_control_node : Control


func _ready():
	# 测试数据
	edit_grid.queue_redraw_data({
		1: {
			2: "hello",
			3: 450293,
		}, 
		2: {
			1: preload("res://icon.svg")
		}
	})


var _last_hover_cell := Vector2i(-1, -1)

func _on_edit_grid_gui_input(event):
	if event is InputEventMouseMotion:
		var cell_coords = edit_grid.get_cell_by_mouse_pos()
		if not edit_grid.is_highlight_cell(cell_coords):
			if _last_hover_cell != cell_coords:
				edit_grid.remove_highlight_cell(_last_hover_cell)
				edit_grid.add_highlight_cell(cell_coords, Color.YELLOW)
				_last_hover_cell = cell_coords


func _on_edit_grid_cell_double_clicked(cell: Vector2i):
	var control_node : Control
	var value = edit_grid.get_data_by_cell(cell)
	if typeof(value) != TYPE_NIL:
		if not value is Object:
			cell_text_edit.text = str(value)
			cell_text_edit.visible = true
			cell_text_edit.set_meta(MetaKey.LAST_CELL, cell)
			control_node = cell_text_edit
		else:
			assert(value is Texture2D or value is Image)
			if value is Image:
				value = ImageTexture.create_from_image(value)
			cell_texture_rect.texture = value
			control_node = cell_texture_rect
	else:
		return
	
	var rect = edit_grid.get_cell_rect(cell) as Rect2
	control_node.visible = true
	control_node.size = edit_grid.get_cell_rect(cell).size
	control_node.position = edit_grid.global_position + rect.position
	last_control_node = control_node


func _on_edit_grid_cell_clicked(cell):
	if last_control_node:
		last_control_node.visible = false


func _on_cell_text_edit_visibility_changed():
	if cell_text_edit and not cell_text_edit.visible:
		var cell = cell_text_edit.get_meta(MetaKey.LAST_CELL)
		if typeof(cell) != TYPE_NIL:
			edit_grid.add_data_by_cell(cell, cell_text_edit.text)


