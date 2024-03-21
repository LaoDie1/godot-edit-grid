#============================================================
#    Plugin
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-17 22:41:21
# - version: 4.2.1
#============================================================
@tool
extends EditorPlugin


const EDIT_MAIN = preload("res://addons/edit_grid/src/eidt_main/edit_main.tscn")

var plugin_control = EDIT_MAIN.instantiate()


func _enter_tree():
	EditorInterface.get_editor_main_screen().add_child(plugin_control)
	plugin_control.hide()
	update_color()
	
	get_editor_interface() \
		.get_base_control() \
		.theme_changed.connect(update_color)


func _exit_tree():
	EditorInterface.get_editor_main_screen().remove_child(plugin_control)

func _has_main_screen():
	return true

func _make_visible(visible):
	plugin_control.visible = visible

func _get_plugin_name():
	return "EditGrid"

func _get_plugin_icon():
	var icon = get_editor_interface() \
		.get_editor_theme() \
		.get_icon("GridContainer", "EditorIcons")
	
	# 转变颜色
	var editor_settings : EditorSettings = get_editor_interface().get_editor_settings()
	var text_color : Color = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
	var v : float = (text_color.r + text_color.g + text_color.b) * 255 / 3
	var data : PackedByteArray = PackedByteArray()
	var image : Image = icon.get_image()
	var idx : int = 0
	for byte in image.get_data():
		idx += 1
		if byte > 0:
			data.push_back(v if idx % 4 != 0 else 255)
		else:
			data.push_back(0)
	
	var new_image : Image = Image.create_from_data(
		image.get_width(),
		image.get_height(),
		image.has_mipmaps(),
		image.get_format(),
		data
	)
	return ImageTexture.create_from_image(new_image)


func update_color():
	var editor_settings : EditorSettings = get_editor_interface().get_editor_settings()
	# 强调颜色
	var accent_color : Color = editor_settings.get_setting("interface/theme/accent_color")
	# 文本颜色
	var text_color : Color = editor_settings.get_setting("text_editor/theme/highlighting/text_color")
	# 线条颜色
	var line_color : Color = editor_settings.get_setting("text_editor/theme/highlighting/line_number_color")
	
	var edit_grid = plugin_control.edit_grid
	edit_grid.data_grid.panel_border_color = line_color
	edit_grid.data_grid.grid_color = line_color
	edit_grid.data_grid.text_color = text_color
	edit_grid.data_grid.selecte_cell_color = accent_color
	edit_grid.top_number_bar.text_color = text_color
	edit_grid.left_number_bar.text_color = text_color
	
