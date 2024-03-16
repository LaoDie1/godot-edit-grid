#============================================================
#    Example
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-16 00:28:11
# - version: 4.0
#============================================================
extends Control


## 测试数据
var TEST_DATA = {
		1: {
			2: "hello",
			3: 450293,
		}, 
		2: {
			1: preload("res://icon.svg")
		}, 
	}

@onready var edit_grid = $EditGrid



#============================================================
#  内置
#============================================================
func _ready():
	var excel = ExcelFile.open_file("res://addons/edit_grid/example/test.xlsx")
	var workbook = excel.get_workbook()
	var sheet = workbook.get_sheet(0)
	var data = sheet.get_table_data()
	edit_grid.set_grid_data(data)
	edit_grid.add_data(0, 0, 100)
	
	# 设置列宽
	edit_grid.set_custom_column_width({
		2: 300,
	})
	edit_grid.set_custom_row_height({
		2: 150,
	})
	
