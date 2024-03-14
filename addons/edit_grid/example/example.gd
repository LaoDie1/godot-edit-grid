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
@onready var cell_texture_rect = $CellTextureRect
@onready var popup_edit_box = $PopupEditBox

var last_control_node : Control


func _ready():
	# 测试数据
	#var file = "D:\\Downloads\\test_2.xlsx"
	#var excel = ExcelFile.open_file(file)
	#var workbook = excel.get_workbook()
	#var sheet = workbook.get_sheet(0)
	#var data = sheet.get_table_data()
	#
	#edit_grid.queue_redraw_data(sheet.get_table_data())
	#return
	
	
	edit_grid.queue_redraw_data({
		1: {
			2: "hello",
			3: 450293,
		}, 
		2: {
			1: preload("res://icon.svg")
		}, 
	})


func _on_edit_grid_cell_double_clicked(cell: Vector2i):
	var control_node : Control # 当前操作的节点
	var value = edit_grid.get_data_by_cell(cell)
	if typeof(value) != TYPE_NIL:
		if not value is Object:
			#popup_edit_box.visible = true
			var rect = edit_grid.get_cell_rect(cell)
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
		print(cell, " 数据为空")
		return
	
	var rect = edit_grid.get_cell_rect(cell) as Rect2
	control_node.visible = true
	control_node.size = edit_grid.get_cell_rect(cell).size
	control_node.position = edit_grid.global_position + rect.position
	last_control_node = control_node


func _on_edit_grid_cell_clicked(cell):
	if last_control_node:
		last_control_node.visible = false


func _on_edit_grid_cell_hovered(cell):
	edit_grid.remove_highlight_cell(edit_grid.get_last_hover_cell())
	edit_grid.add_highlight_cell(cell, Color.YELLOW)


func _on_popup_edit_box_popup_hide(text):
	if popup_edit_box and not popup_edit_box.visible:
		var cell = popup_edit_box.get_meta(MetaKey.LAST_CELL)
		if typeof(cell) != TYPE_NIL:
			var last_data = edit_grid.get_data_by_cell(cell)
			if typeof(last_data) == TYPE_NIL or str(last_data) != popup_edit_box.text:
				edit_grid.add_data_by_cell(cell, popup_edit_box.text)
		popup_edit_box.remove_meta(MetaKey.LAST_CELL)


func _on_popup_edit_box_input_switch_char(character):
	popup_edit_box.hide()
