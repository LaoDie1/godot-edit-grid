#============================================================
#    Number Bar
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-16 03:10:14
# - version: 4.2.1
#============================================================
@tool
extends Panel


## 显示的文本颜色
@export var text_color : Color = Color.WHITE:
	set(v):
		text_color = v
		queue_redraw()
## 绘制方向
@export_enum("Column", "Row") var draw_direction : int = 0:
	set(v):
		draw_direction = v
		queue_redraw()
## 默认间隔距离
@export var default_width : int = 90:
	set(v):
		default_width = v
		queue_redraw()
## 字符的形式展示
@export var character_format : bool = false:
	set(v):
		character_format = v
		queue_redraw()

var _offset : int = 0
var _blank_width : Dictionary = {}
var _p_list : Array = [] # 点位列表



#============================================================
#  内置
#============================================================
func _init():
	clip_contents = true

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
		if draw_direction == 1:
			rect.position.y += max(0, rect.size.y - height) / 2 - 4
		var num_idx = i + _offset 
		draw_string(
			font, 
			rect.position + Vector2(0, height), 
			str(num_idx) if not character_format else to_26_base(num_idx), 
			HORIZONTAL_ALIGNMENT_CENTER, 
			rect.size.x, 
			get_theme_default_font_size(),
			text_color
		)


#============================================================
#  自定义
#============================================================
# 转为 26 进制
static func to_26_base(dividend: int) -> String:
	const BASE = 26
	if dividend == 0:
		return "@"
	var result = []
	var quotient : int = dividend
	var remainder : int
	while quotient > 0:
		quotient = dividend / BASE
		remainder = dividend % BASE
		if remainder > 0:
			result.append(
				char( (remainder if remainder > 0 else BASE) + 64 )
			)
		else:
			result.append(char(BASE + 64))
			quotient -= 1
			if quotient > 0:
				result.append(char(quotient + 64))
			break
		dividend = quotient
	
	result.reverse()
	return "".join(result)


## 每个序号的空白宽度
func redraw(offset: int, blank_width: Dictionary):
	_offset = offset
	_blank_width = blank_width
	queue_redraw()

