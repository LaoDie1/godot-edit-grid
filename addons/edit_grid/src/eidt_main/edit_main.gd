#============================================================
#    Edit Main
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-17 22:35:08
# - version: 4.0
#============================================================
## 主编辑窗口
##
##整体界面场景。对编辑的数据进行保存、加载等
@tool
extends MarginContainer


@onready var menu = %Menu
@onready var edit_grid = %EditGrid
@onready var file_path_label = %FilePathLabel
@onready var save_status_label = %SaveStatusLabel

var _save_status : bool = true:
	set(v):
		if _save_status != v:
			_save_status = v
			save_status_label.text = "Saved" if _save_status else "Not Saved"
			save_status_label.modulate = (
				Color.WHITE if _save_status else Color.ORANGE
			)
			save_status_label.modulate.a = 0.8


#============================================================
#  内置
#============================================================
func _ready():
	# 初始化菜单
	menu.init_menu({
		"File": [ "Print", "Save", "Save As" ]
	})
	
	# 设置快捷键
	menu.set_menu_shortcut("/File/Print", {
		"ctrl": true,
		"keycode": KEY_P,
	})
	menu.set_menu_shortcut("/File/Save", {
		"ctrl": true,
		"keycode": KEY_S,
	})
	menu.set_menu_shortcut("/File/Save As", {
		"ctrl": true,
		"shift": true,
		"keycode": KEY_S,
	})



#============================================================
#  连接信号
#============================================================
func _on_menu_menu_pressed(idx: int, menu_path: StringName) -> void:
	print(menu_path)
	match menu_path:
		"/File/Print":
			_save_status = true
			print("打印数据：", edit_grid.get_grid_data())
		
		_:
			print("没有实现功能。菜单路径：", menu_path)


func _on_edit_grid_cell_value_changed(cell, last_value, current_value):
	_save_status = false

