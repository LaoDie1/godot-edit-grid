#============================================================
#    Number Bar
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-16 03:10:14
# - version: 4.0
#============================================================
extends Panel


## 绘制方向
@export_enum("Column", "Row") var draw_direction : int = 0
## 默认间隔距离
@export var default_width = 90
## 字符的形式展示
@export var character_format : bool = false

var _offset : int = 0
var _blank_width : Dictionary = {}
var _p_list : Array = [] # 点位列表


#============================================================
#  内置
#============================================================
func _draw():
	_p_list.clear()
	var idx = _offset
	var p = 0
	while p < size[draw_direction]:
		_p_list.append(p)
		p += _blank_width.get(idx, default_width)
		idx += 1
	_p_list.append(p)
	
	for i in range( _p_list.size()-1 ):
		var font : Font = get_theme_default_font()
		var height = font.get_height()
		
		var rect = Rect2()
		rect.position[draw_direction] = _p_list[i]
		rect.size[draw_direction] = _p_list[i+1] - _p_list[i]
		rect.size[abs(draw_direction-1)] = size[abs(draw_direction-1)]
		#if draw_direction == 1:
			#rect.position.y -= max(0, rect.size.y - height) / 2
		var num_idx = i + _offset 
		draw_string(
			font, 
			rect.position + Vector2(0, height), 
			str(num_idx) if not character_format else _to_26_base(num_idx), 
			HORIZONTAL_ALIGNMENT_CENTER, 
			rect.size.x, 
			get_theme_default_font_size()
		)


#============================================================
#  自定义
#============================================================
# 转为 26 进制
static func _to_26_base(num: int) -> String:
	num -= 1
	var value : String = ""
	for i in range(1, 16):
		var power_value = (26 ** i)
		var result : int = num / power_value
		if result > 0:
			value += char(result + 64)
		else:
			value += char(num + 65)
			break
		num -= power_value
	return value


## 每个序号的空白宽度
func redraw(offset: int, blank_width: Dictionary):
	_offset = offset
	_blank_width = blank_width
	queue_redraw()

