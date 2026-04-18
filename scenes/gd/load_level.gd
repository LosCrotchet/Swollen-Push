extends Node

@export var map_editor: Control
@export var level_list: ItemList
@export var base_tilemap: TileMapLayer
@export var level_title: Label
@export var level_hint: Label
@export var map_panel: Panel

var _now_level = -1
const BASE_POSITION = Vector2(512, 128)

var all_levels

func _ready() -> void:
	GridManager.level_finished.connect(_on_load_next_level)
	_on_refresh_button_pressed()

func log_print(s: String):
	print("[%s] %s" % [Time.get_time_string_from_system(), s])

func _get_levels():
	var file = FileAccess.open("res://levels.json", FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		log_print("JSON 解析失败，错误行: " + str(json.get_error_line()))
		return {}
	
	var data = json.data
	return data

func _on_refresh_button_pressed() -> void:
	all_levels = _get_levels()
	
	level_list.clear()
	for item in all_levels:
		level_list.add_item(item)
	if level_list.item_count:
		_now_level = 0
		load_level(level_list.get_item_text(_now_level))
		level_title.text = level_list.get_item_text(_now_level)
		level_hint.text = all_levels[level_list.get_item_text(_now_level)]["hint"]
	else:
		level_title.text = ""
		level_hint.text = ""

func _on_load_button_pressed() -> void:
	var select_item = level_list.get_selected_items()
	if select_item:
		load_level(level_list.get_item_text(select_item[0]))
		_now_level = select_item[0]
		level_title.text = level_list.get_item_text(_now_level)
		level_hint.text = all_levels[level_list.get_item_text(_now_level)]["hint"]
	else:
		level_title.text = ""
		level_hint.text = ""

func _on_load_next_level():
	if _now_level >= 0:
		_now_level += 1
		if _now_level < level_list.item_count:
			load_level(level_list.get_item_text(_now_level))
			level_title.text = level_list.get_item_text(_now_level)
			level_hint.text = all_levels[level_list.get_item_text(_now_level)]["hint"]
		else:
			level_title.text = "CONGRATULATIONS"
			level_hint.text = "你已完成所有关卡！"


func _is_valid_base64(s: String) -> bool:
	if not s or len(s) % 4 != 0:
		return false
	var valid_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
	for c in s:
		if c not in valid_chars:
			return false
	return true

func _is_valid_map_data(s: String) -> bool:
	if not s or len(s) != GameManager.WIDTH*GameManager.HEIGHT:
		return false
	var valid_chars = "0123456789"
	for c in s:
		if c not in valid_chars:
			return false
	return true

# ==========================================
# 读取地图 (高级版：不规则内腔提取与自适应边框)
# ==========================================
func load_level(level_name: String):
	var map_data = all_levels.get(level_name, {})
	if map_data == {}:
		log_print("找不到关卡：" + level_name)
		return
	
	log_print("加载关卡：" + level_name)
	
	map_data = map_data["data"]
	if not _is_valid_base64(map_data):
		log_print("地图字符串的格式错误，不符合Base64编码规范！")
		return
	
	var all_data = []
	map_data = Marshalls.base64_to_utf8(map_data)
	
	if not _is_valid_map_data(map_data):
		log_print("解析后的地图数据错误！")
		return
	
	for i in range(len(map_data)):
		if int(map_data[i]) != 0:
			@warning_ignore("integer_division")
			var obj_data = {
				"x": i%GameManager.WIDTH,
				"y": i/GameManager.WIDTH,
				"type": int(map_data[i])-1,
				"radius": 1
			}
			all_data.append(obj_data)
	
	# 1. 清理当前场上所有物体
	for item in get_tree().get_nodes_in_group("OBJECT"):
		item.remove_from_group("OBJECT")
		item.remove_from_group("CUBE")
		item.remove_from_group("WALL")
		item.remove_from_group("FIREBALL")
		item.remove_from_group("FIREPIT")
		item.queue_free()

	log_print("地图清空完成！")
	# --- 优化步骤 1：解析不规则地图形态 ---
	var wall_coords = {}      # 记录所有墙壁的坐标
	var interior_coords = {}  # 记录所有非墙壁（内腔）的坐标
	
	
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
	
	if map_panel:
		map_panel.position = visual_offset + BASE_POSITION
		map_panel.size = Vector2(max_x - min_x + 1, max_y - min_y + 1) * 64
		
	log_print("使MapPanel居中")
	
	if base_tilemap:
		base_tilemap.clear()
	#map_editor.position = visual_offset

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

	log_print("地图地板绘制完成！")
	# --- 优化步骤 4：还原物体并剔除多余墙壁 ---
	for obj_data in all_data:
		var type = obj_data["type"]
		var c = Vector2i(obj_data["x"], obj_data["y"])
		
		var coord = Vector2(c.x, c.y)
		var radius = obj_data.get("radius", 1)
		
		var obj = map_editor.create(type, coord, radius)
		
		# 如果是墙壁，且不在我们计算出的有效边界内，则作为无用填充剔除
		if type == GameManager.CONTENT.WALL and not valid_map_coords.has(c):
			obj.visible = false
		
	log_print("地图读取完成！")
