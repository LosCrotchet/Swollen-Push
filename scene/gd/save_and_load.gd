extends Node

@export var map_editor: Control
@export var log: Control
@export var base_tilemap: TileMapLayer # 请在属性面板中将 MapPanel 下的 Base 拖入此变量
@export var cursor_tilemap: TileMapLayer

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
# 读取地图 (高级版：不规则内腔提取与自适应边框)
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

	# --- 优化步骤 1：解析不规则地图形态 ---
	var wall_coords = {}      # 记录所有墙壁的坐标
	var interior_coords = {}  # 记录所有非墙壁（内腔）的坐标
	
	var all_data = data.get("objects", []) + data.get("props", [])
	
	# 提取 json 中的墙壁坐标
	for obj in all_data:
		var c = Vector2i(obj["x"], obj["y"])
		if obj["type"] == GameManager.CONTENT.WALL:
			wall_coords[c] = true
			
	# 推导内腔：在 16x12 范围内，所有不是墙的格子，都视为玩家活动内腔
	for x in range(GameManager.WIDTH):
		for y in range(GameManager.HEIGHT):
			var c = Vector2i(x, y)
			if not wall_coords.has(c):
				interior_coords[c] = true

	var valid_map_coords = {} # 最终要保留的地图格子（内腔 + 边界墙）
	
	# 将所有内腔加入有效地图
	for c in interior_coords.keys():
		valid_map_coords[c] = true
		
	# 找出边界墙：只要一面墙的 8 个邻居中有任何一个是内腔，它就是边界
	#for wall_c in wall_coords.keys():
		#var is_boundary = false
		#for dx in [-1, 0, 1]:
			#for dy in [-1, 0, 1]:
				#if dx == 0 and dy == 0: continue
				#var neighbor = wall_c + Vector2i(dx, dy)
				#if interior_coords.has(neighbor):
					#is_boundary = true
					#break
			#if is_boundary: break
			
		#if is_boundary:
		#	valid_map_coords[wall_c] = true

	# --- 优化步骤 2：重新计算视觉居中偏移 ---
	var min_x = 9999; var max_x = -9999
	var min_y = 9999; var max_y = -9999
	
	for c in valid_map_coords.keys():
		if c.x < min_x: min_x = c.x
		if c.x > max_x: max_x = c.x
		if c.y < min_y: min_y = c.y
		if c.y > max_y: max_y = c.y
		
	# 计算裁切后地图的中心像素点 (网格大小为 64，半格为 32)
	var map_center_x = (min_x + max_x + 1) * 32.0 
	var map_center_y = (min_y + max_y + 1) * 32.0 
	
	# 偏移至 MapPanel 的中心点 (512, 384)
	var visual_offset = Vector2(512.0 - map_center_x, 384.0 - map_center_y)
	
	if base_tilemap:
		base_tilemap.position = visual_offset
		base_tilemap.clear()
		cursor_tilemap.position = visual_offset
	map_editor.position = visual_offset

	# --- 优化步骤 3：自适应绘制不规则 9-Slice 地板 ---
	if base_tilemap:
		for c in valid_map_coords.keys():
			var x = c.x
			var y = c.y
			
			# 判断四周是否“悬空”（即相邻格子不在有效地图内）
			var U = not valid_map_coords.has(Vector2i(x, y - 1))
			var D = not valid_map_coords.has(Vector2i(x, y + 1))
			var L = not valid_map_coords.has(Vector2i(x - 1, y))
			var R = not valid_map_coords.has(Vector2i(x + 1, y))
			
			var atlas_coords = Vector2i(0, 0) # 默认网格
			
			# 根据悬空情况自动分配 Tile 坐标
			if U and D and L and R: atlas_coords = Vector2i(2, 3)
			elif U and D and L: atlas_coords = Vector2i(0, 2)
			elif U and D and R: atlas_coords = Vector2i(3, 2)
			elif U and R and L: atlas_coords = Vector2i(1, 2)
			elif R and D and L: atlas_coords = Vector2i(2, 2)
			elif U and D: atlas_coords = Vector2i(0, 3)
			elif L and R: atlas_coords = Vector2i(1, 3)
			elif U and L: atlas_coords = Vector2i(0, 1)    # 左上边框
			elif D and L: atlas_coords = Vector2i(1, 1)    # 左下边框
			elif D and R: atlas_coords = Vector2i(2, 1)    # 右下边框
			elif U and R: atlas_coords = Vector2i(3, 1)    # 右上边框
			elif U: atlas_coords = Vector2i(1, 0)          # 上边框
			elif L: atlas_coords = Vector2i(2, 0)          # 左边框
			elif R: atlas_coords = Vector2i(3, 0)          # 右边框
			elif D: atlas_coords = Vector2i(4, 0)          # 下边框
			
			# 假设 TileSet 的 source_id 是 1
			base_tilemap.set_cell(c, 1, atlas_coords)

	# --- 优化步骤 4：还原物体并剔除多余墙壁 ---
	for obj_data in data.get("objects", []):
		var type = obj_data["type"]
		var c = Vector2i(obj_data["x"], obj_data["y"])
		
		var coord = Vector2(c.x, c.y)
		var radius = obj_data.get("radius", 1)
		
		var obj = map_editor.create(type, coord, radius)
		
		# 如果是墙壁，且不在我们计算出的有效边界内，则作为无用填充剔除
		if type == GameManager.CONTENT.WALL and not valid_map_coords.has(c):
			obj.visible = false

	for prop_data in data.get("props", []):
		var coord = Vector2(prop_data["x"], prop_data["y"])
		map_editor.create(GameManager.CONTENT.HOLE, coord)
		
	log_print("地图读取完成！")
