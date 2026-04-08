extends Node

@export var map_editor: Control
@export var log: Control

const CUBE_SCENE = preload("res://scene/cube.tscn")
const BOX_SCENE = preload("res://scene/box.tscn")
const WALL_SCENE = preload("res://scene/wall.tscn")
const HOLE_SCENE = preload("res://scene/hole.tscn")

func _on_save_button_pressed() -> void:
	save_level()

func _on_load_button_pressed() -> void:
	load_level()

func log_print(s: String):
	log.text = "[%s] %s" % [Time.get_time_string_from_system(), s]

# ==========================================
# 存档路径获取逻辑 (兼容编辑器与导出的 exe)
# ==========================================
func get_save_path() -> String:
	if OS.has_feature("editor"):
		# 在编辑器中运行，保存在项目根目录的真实物理路径下
		return ProjectSettings.globalize_path("res://level.json")
	else:
		# 导出为 exe 后，保存在 exe 所在的同级目录下
		return OS.get_executable_path().get_base_dir().path_join("level.json")

# ==========================================
# 保存地图
# ==========================================
func save_level():
	var save_dict = {
		"width": GameManager.WIDTH,
		"height": GameManager.HEIGHT,
		"objects": [],
		"props": []
	}
	
	# 1. 保存所有 Objects
	for item in get_tree().get_nodes_in_group("Objects"):
		var obj_data = {
			"type": item.type,
			"x": item.coordinate.x,
			"y": item.coordinate.y,
			"mass": item.mass,
			"radius": item.radius
		}
			
		save_dict["objects"].append(obj_data)
		
	# 2. 保存所有的 props (标记/洞)
	for item in get_tree().get_nodes_in_group("props"):
		save_dict["props"].append({
			"type": item.type,
			"x": item.coordinate.x,
			"y": item.coordinate.y,
			"mass": item.mass,
			"radius": item.radius
		})
		
	# 3. 写入 JSON 文件
	var path = get_save_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		# 使用 "\t" 缩进让生成的 json 文件可读性更好（方便手动改图）
		file.store_string(JSON.stringify(save_dict, "\t"))
		file.close()
		log_print("地图已保存至: " + path)
	else:
		log_print("保存失败，无法写入文件: " + path)

# ==========================================
# 读取地图
# ==========================================
func load_level():
	var path = get_save_path()
	if not FileAccess.file_exists(path):
		log_print("找不到存档文件: " + path)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		log_print("JSON 解析失败，错误行: " + str(json.get_error_line()))
		return
		
	var data = json.data
	
	# 1. 清理当前场上所有物体
	for item in get_tree().get_nodes_in_group("props"):
		item.remove_from_group("props")
		item.queue_free()
	for item in get_tree().get_nodes_in_group("Objects"):
		item.remove_from_group("Objects")
		item.remove_from_group("cubes")
		item.remove_from_group("walls")
		item.remove_from_group("boxes")
		item.queue_free()

	# 2. 还原 Objects (方块、箱子、墙壁)
	for obj_data in data.get("objects", []):
		var coord = Vector2(obj_data["x"], obj_data["y"])
		var type = obj_data["type"]
		var radius = obj_data.get("radius", 1)
		
		map_editor.create(type, coord, radius)

	# 4. 还原 Props (洞/标记)
	for prop_data in data.get("props", []):
		var coord = Vector2(prop_data["x"], prop_data["y"])
		
		map_editor.create(GameManager.CONTENT.HOLE, coord)
		
	log_print("地图读取完成！")
