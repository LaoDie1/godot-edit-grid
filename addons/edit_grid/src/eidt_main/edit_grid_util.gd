#============================================================
#    Edit Grid Util
#============================================================
# - author: zhangxuetu
# - datetime: 2024-03-20 19:10:25
# - version: 4.2.1
#============================================================
class_name EditGridUtil



static func get_csv_file_data(path: String, delim: String = ",", column_row_offset: Vector2i = Vector2i(0, 0)) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	var row : int = column_row_offset.y
	var data : Dictionary = {}
	var line : PackedStringArray = file.get_csv_line(delim)
	while not (line.size() == 1 and line[0] == ""):
		# 记录数据
		var column_data = {}
		for column in line.size():
			column_data[column + column_row_offset.x ] = line[column]
		data[row] = column_data
		# 下一行
		line = file.get_csv_line(delim)
		row += 1
	return data


static func save_data_to_csv(data: Dictionary, path: String, delim: String = ","):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var rows = data.keys()
	rows.sort()
	var column_data : Dictionary
	var line_data : PackedStringArray
	
	# 所有的列
	var columns = {}
	for row in rows:
		column_data = data[row]
		for column in column_data:
			columns[column] = null
	
	# 列排序
	columns = columns.keys()
	columns.sort()
	for row in rows:
		column_data = data[row]
		line_data = PackedStringArray()
		for column in columns:
			line_data.push_back(column_data.get(column, ""))
		if not line_data.is_empty():
			file.store_csv_line( line_data, delim )
	
	var import_path = path + ".import"
	var import_file = FileAccess.open(import_path, FileAccess.WRITE)
	import_file.store_string("""[remap]

importer="keep"

""")

