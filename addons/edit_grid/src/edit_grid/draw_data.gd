#============================================================
#    Draw Data
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-17 18:02:47
# - version: 4.2.1
#============================================================
## 绘制到网格上的数据
##
##你可以修改 [code]enabled[/code] 值为 [code]false[/code] 阻止绘制操作，自定义绘制内容
class_name DrawData
extends RefCounted


## 是否允许绘制
var enabled : bool = true
## 绘制到的单元格位置
var cell : Vector2i
## 绘制的数据值
var value

