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

func _exit_tree():
	EditorInterface.get_editor_main_screen().remove_child(plugin_control)

func _has_main_screen():
	return true

func _make_visible(visible):
	plugin_control.visible = visible

func _get_plugin_name():
	return "EditGrid"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("GridContainer", "EditorIcons")

