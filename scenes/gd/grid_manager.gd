extends Node

signal level_finished

# ==========================================
# 辅助判定：处理特定的无视碰撞/允许重合的情况
# ==========================================
func _can_overlap(obj_a: Node, obj_b: Node) -> bool:
	if not is_instance_valid(obj_a) or not is_instance_valid(obj_b):
		return false
	
	var type_a = obj_a.type
	var type_b = obj_b.type
	
	# 火球与火盆相遇时允许重合，跳过物理碰撞校验
	if (type_a == GameManager.CONTENT.FIREBALL and type_b == GameManager.CONTENT.FIREPIT) or \
	   (type_a == GameManager.CONTENT.FIREPIT and type_b == GameManager.CONTENT.FIREBALL):
		return true
		
	return false

# ==========================================
# 核心引擎：计算所有连带运动并验证 (BFS 算法)
# ==========================================
func _calculate_kinematic_chain(initial_moves: Dictionary, ignore_objects: Array = []) -> Dictionary:
	var moving_objects = {}
	var queue = []

	for obj in initial_moves:
		moving_objects[obj] = initial_moves[obj]
		queue.append(obj)

	# 1. 广度优先遍历所有受波及的物体
	while queue.size() > 0:
		var curr = queue.pop_front()
		var dir = moving_objects[curr]
		var curr_rect = curr.get_rect()
		var next_rect = curr.get_rect(curr.coordinate + dir)
		
		for other in get_tree().get_nodes_in_group("OBJECT"):
			if other == curr or other in ignore_objects:
				continue
			
			var other_rect = other.get_rect()
			var is_pushed = next_rect.intersects(other_rect)
			
			# 【火球/火盆修复】：如果双方属于允许重合的关系，不作为推挤处理，直接允许当前物体进入其空间
			if is_pushed and _can_overlap(curr, other):
				is_pushed = false
			
			# 跟随/补位免除物理推挤
			if is_pushed and moving_objects.has(other) and moving_objects[other] == dir:
				is_pushed = false
			
			var is_stuck = false
			if not is_pushed:
				# 模拟相邻检测（注意这里保留了基于包围盒的扩张逻辑，确保膨胀收缩时空间越界的准确判断）
				var expanded_curr = Rect2i(curr_rect.position - Vector2i(1, 1), curr_rect.size + Vector2i(2, 2))
				if expanded_curr.intersects(other_rect) and not curr_rect.intersects(other_rect):
					if curr.type == GameManager.CONTENT.CUBE_STICKY or other.type == GameManager.CONTENT.CUBE_STICKY:
						is_stuck = true
						
			if is_pushed or is_stuck:
				if other.type == GameManager.CONTENT.WALL or other.type == GameManager.CONTENT.CUBE_FIXED:
					if is_pushed:
						return {} # 推不动死物，运动崩溃
					else:
						continue  # 黏性方块拉不动死物，跳过
						
				if is_pushed and curr.mass < other.mass:
					return {} # 质量不足，推不动
				elif is_stuck and curr.mass < other.mass:
					continue # 粘连断开
					
				if moving_objects.has(other):
					if moving_objects[other] != dir:
						return {} # 发生挤压/拉扯冲突
				else:
					moving_objects[other] = dir
					queue.append(other)

	# 2. 验证阶段：终点合法性与越界
	var target_rects = []
	for obj in moving_objects:
		var final_rect = obj.get_rect(obj.coordinate + moving_objects[obj])
		if final_rect.position.x < 0 or final_rect.position.y < 0 or final_rect.end.x > GameManager.WIDTH or final_rect.end.y > GameManager.HEIGHT:
			return {}
		target_rects.append({ "obj": obj, "rect": final_rect })

	# 3. 重叠验证
	for i in range(target_rects.size()):
		for j in range(i + 1, target_rects.size()):
			if target_rects[i]["rect"].intersects(target_rects[j]["rect"]):
				if not _can_overlap(target_rects[i]["obj"], target_rects[j]["obj"]):
					return {}
				
		for other in get_tree().get_nodes_in_group("OBJECT"):
			if other in moving_objects or other in ignore_objects:
				continue
			var other_rect = other.get_rect()
			if target_rects[i]["rect"].intersects(other_rect):
				if not _can_overlap(target_rects[i]["obj"], other):
					return {}
				
	return moving_objects

# ==========================================
# 核心互动：更新方块与膨胀检测
# ==========================================
func apply_cube_scaling(coord: Vector2i, delta: int = 1) -> bool:
	var facing_cube = null
	for item in get_tree().get_nodes_in_group("CUBE"):
		if item.get_rect().has_point(coord):
			facing_cube = item
			break
			
	if not facing_cube:
		return false
	
	var origin_radius = facing_cube.radius
	var to_radius = origin_radius + delta
	var is_exploding = (to_radius == 4 and facing_cube.type == GameManager.CONTENT.CUBE_BOOM)

	# 半径合法性校验
	if not is_exploding and (to_radius < 1 or to_radius > 3):
		GameManager.shake(facing_cube)
		return false
	
	var new_rect = facing_cube.get_rect(facing_cube.coordinate, to_radius)
	
	# 边界校验 (爆炸时无视边界)
	if not is_exploding:
		if new_rect.position.x < 0 or new_rect.position.y < 0 or new_rect.end.x > GameManager.WIDTH or new_rect.end.y > GameManager.HEIGHT:
			GameManager.shake(facing_cube)
			return false

	var initial_moves = {}
	
	# ================= 膨胀产生的外推力 (Delta > 0) =================
	if delta > 0:
		for target in get_tree().get_nodes_in_group("OBJECT"):
			if target == facing_cube: continue
			var target_rect = target.get_rect()
			
			if new_rect.intersects(target_rect):
				if is_exploding:
					# 爆炸方块：无视墙壁和固定方块（不加入受力列表），但对其他物体施加推力
					if target.type != GameManager.CONTENT.WALL and target.type != GameManager.CONTENT.CUBE_FIXED:
						initial_moves[target] = target.get_push_dir(facing_cube.coordinate)
				else:
					# 普通方块：撞到墙壁/固定方块/大质量物体，直接膨胀失败
					if target.type == GameManager.CONTENT.CUBE_FIXED or target.type == GameManager.CONTENT.WALL or facing_cube.mass < target.mass:
						GameManager.shake(facing_cube)
						return false
					initial_moves[target] = target.get_push_dir(facing_cube.coordinate)

	# ================= 收缩产生的内拉力 (Delta < 0) =================
	elif delta < 0:
		var old_rect = facing_cube.get_rect(facing_cube.coordinate, origin_radius)
		for target in get_tree().get_nodes_in_group("OBJECT"):
			if target == facing_cube: continue
			
			if facing_cube.type != GameManager.CONTENT.CUBE_STICKY and target.type != GameManager.CONTENT.CUBE_STICKY:
				continue
				
			var target_rect = target.get_rect()
			var expanded_old = Rect2i(old_rect.position - Vector2i(1,1), old_rect.size + Vector2i(2,2))
			
			if expanded_old.intersects(target_rect) and not old_rect.intersects(target_rect):
				if target.type == GameManager.CONTENT.CUBE_FIXED or target.type == GameManager.CONTENT.WALL or facing_cube.mass < target.mass:
					continue
				initial_moves[target] = -target.get_push_dir(facing_cube.coordinate)

	# 计算所有的后续连锁反应
	var moves = {}
	if not initial_moves.is_empty():
		moves = _calculate_kinematic_chain(initial_moves, [facing_cube])
		if moves.is_empty():
			if not is_exploding:
				GameManager.shake(facing_cube)
				return false
			else:
				# 爆炸特性：如果受到牵连的物体被卡住（比如火球被推到了墙角），
				# 此时依然不阻碍爆炸方块本身的引爆与消失，只是受力物体不移动。
				moves = {} 

	# 额外检查与兜底验证
	if not is_exploding:
		if not moves.is_empty():
			for m_obj in moves:
				var final_rect = m_obj.get_rect(m_obj.coordinate + moves[m_obj])
				if final_rect.intersects(new_rect):
					GameManager.shake(facing_cube)
					return false
					
		for target in get_tree().get_nodes_in_group("OBJECT"):
			if target == facing_cube or moves.has(target): continue
			var target_rect = target.get_rect()
			if new_rect.intersects(target_rect):
				# 如果膨胀出的空间压到了没有移动的物体（且不是合法的火球火盆叠加）
				if not _can_overlap(facing_cube, target):
					GameManager.shake(facing_cube)
					return false

	# 3. 落实表现与移动
	facing_cube.set_radius(to_radius)
	
	if is_exploding:
		facing_cube.remove_from_group("CUBE")
		facing_cube.remove_from_group("OBJECT")
		facing_cube.queue_free()
	
	for obj in moves:
		if obj.has_method("move_to"):
			obj.move_to(obj.coordinate + moves[obj])

	# 检查通关条件：考虑到坐标可能通过 move_to 即时更新或进行中
	for item in get_tree().get_nodes_in_group("FIREBALL"):
		var is_finished = false
		for hole in get_tree().get_nodes_in_group("FIREPIT"):
			# 火球和火洞的坐标重合即为判定成功
			if item.coordinate == hole.coordinate:
				is_finished = true
				break
		if not is_finished:
			return true
	
	level_finished.emit()
	return true
