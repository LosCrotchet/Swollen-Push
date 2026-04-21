extends Node

signal level_finished

@export var enable = true

# ==========================================
# 辅助判定 1：处理特定的无视碰撞/允许重合的情况
# ==========================================
func _can_overlap(obj_a: Node, obj_b: Node) -> bool:
	if not is_instance_valid(obj_a) or not is_instance_valid(obj_b):
		return false
	
	var type_a = obj_a.type
	var type_b = obj_b.type
	
	if (type_a == GameManager.CONTENT.FIREBALL and type_b == GameManager.CONTENT.FIREPIT) or \
	   (type_a == GameManager.CONTENT.FIREPIT and type_b == GameManager.CONTENT.FIREBALL):
		return true
		
	return false

# ==========================================
# 辅助判定 2：运动合法性校验与斜向运动分解 (推挤/黏连通用)
# 加入 moving_objects 参数，能够预判障碍物是否会移走
# ==========================================
func _get_valid_slide_dir(obj: Node, intended_dir: Vector2i, ignore_list: Array = [], moving_objects: Dictionary = {}) -> Vector2i:
	if intended_dir == Vector2i.ZERO:
		return Vector2i.ZERO

	# 局部闭包函数：检测某个方向上是否有障碍物
	var is_blocked = func(d: Vector2i) -> bool:
		var rect = obj.get_rect(obj.coordinate + d)
		# 越界检测
		if rect.position.x < 0 or rect.position.y < 0 or rect.end.x > GameManager.WIDTH or rect.end.y > GameManager.HEIGHT:
			return true
			
		# 遍历障碍物重叠
		for other in get_tree().get_nodes_in_group("OBJECT"):
			if other == obj or other in ignore_list: 
				continue
				
			# 【核心修复】：如果障碍物已经在运动队列中，使用它“未来”的位置进行判定
			var other_rect = other.get_rect()
			if moving_objects.has(other):
				other_rect = other.get_rect(other.coordinate + moving_objects[other])

			if rect.intersects(other_rect):
				# 允许特定重合（如火球火盆）
				if _can_overlap(obj, other):
					continue
				if other.type == GameManager.CONTENT.WALL or other.type == GameManager.CONTENT.CUBE_FIXED:
					return true
				# 对于推挤和黏连，如果障碍物比自己重，也视为阻挡
				if obj.mass < other.mass:
					return true
		return false

	if not is_blocked.call(intended_dir):
		return intended_dir

	if intended_dir.x != 0 and intended_dir.y != 0:
		var dir_x = Vector2i(intended_dir.x, 0)
		var dir_y = Vector2i(0, intended_dir.y)

		var block_x = is_blocked.call(dir_x)
		var block_y = is_blocked.call(dir_y)

		if not block_x and block_y:
			return dir_x
		elif block_x and not block_y:
			return dir_y

	return Vector2i.ZERO

# ==========================================
# 核心引擎：计算所有连带运动并验证 (BFS 算法)
# ==========================================
func _calculate_kinematic_chain(initial_moves: Dictionary, ignore_objects: Array = []) -> Dictionary:
	var moving_objects = {}
	var queue = []

	for obj in initial_moves:
		moving_objects[obj] = initial_moves[obj]
		queue.append(obj)

	while queue.size() > 0:
		var curr = queue.pop_front()
		
		var collision_handled = false
		while not collision_handled:
			collision_handled = true
			var dir = moving_objects[curr]
			var curr_rect = curr.get_rect()
			var next_rect = curr.get_rect(curr.coordinate + dir)
			
			# ==========================================
			# 第一阶段：提前预判推挤阻挡与自身运动分解
			# ==========================================
			var hit_obstacle = false
			for other in get_tree().get_nodes_in_group("OBJECT"):
				if other == curr or other in ignore_objects:
					continue
					
				var other_rect_curr = other.get_rect()
				var other_rect_future = other_rect_curr
				if moving_objects.has(other):
					other_rect_future = other.get_rect(other.coordinate + moving_objects[other])
					
				var is_pushed = next_rect.intersects(other_rect_curr)
				
				if is_pushed and _can_overlap(curr, other):
					continue
				
				# 【核心修复】：如果 other 也在移动，且它同向补位或直接让出了空间，则不构成推挤阻碍
				if is_pushed and moving_objects.has(other):
					if moving_objects[other] == dir or not next_rect.intersects(other_rect_future):
						continue
					
				if is_pushed:
					if other.type == GameManager.CONTENT.WALL or other.type == GameManager.CONTENT.CUBE_FIXED or curr.mass < other.mass:
						hit_obstacle = true
						break
			
			if hit_obstacle:
				# 自身推挤受阻，尝试进行滑动分解，传入 moving_objects 让分解器识别动态空间
				var slide_dir = _get_valid_slide_dir(curr, dir, ignore_objects, moving_objects)
				if slide_dir == Vector2i.ZERO or slide_dir == dir:
					return {} # 完全受阻或挤在角落，整个运动链崩溃
				
				moving_objects[curr] = slide_dir
				collision_handled = false
				continue
				
			# ==========================================
			# 第二阶段：确认无阻挡后，落实推力与拉力的传导
			# ==========================================
			for other in get_tree().get_nodes_in_group("OBJECT"):
				if other == curr or other in ignore_objects:
					continue
				
				var other_rect_curr = other.get_rect()
				var other_rect_future = other_rect_curr
				if moving_objects.has(other):
					other_rect_future = other.get_rect(other.coordinate + moving_objects[other])
				
				var is_pushed = next_rect.intersects(other_rect_curr)
				
				if is_pushed and _can_overlap(curr, other):
					is_pushed = false
				
				if is_pushed and moving_objects.has(other):
					if moving_objects[other] == dir or not next_rect.intersects(other_rect_future):
						is_pushed = false
				
				var is_stuck = false
				if not is_pushed:
					# 黏连检测依旧基于当前时刻（移动前）的位置关系判断
					var expanded_curr = Rect2i(curr_rect.position - Vector2i(1, 1), curr_rect.size + Vector2i(2, 2))
					if expanded_curr.intersects(other_rect_curr) and not curr_rect.intersects(other_rect_curr):
						if curr.type == GameManager.CONTENT.CUBE_STICKY or other.type == GameManager.CONTENT.CUBE_STICKY:
							is_stuck = true
							
				if is_pushed:
					if moving_objects.has(other):
						if moving_objects[other] != dir:
							return {} # 挤压冲突
					else:
						moving_objects[other] = dir
						queue.append(other)
						
				elif is_stuck:
					if other.type == GameManager.CONTENT.WALL or other.type == GameManager.CONTENT.CUBE_FIXED or curr.mass < other.mass:
						continue # 拉不动，断开拉扯
						
					var pull_ignore = ignore_objects.duplicate()
					pull_ignore.append(curr) # 忽略施加拉力的源头
					# 传入 moving_objects 以预判让路情况
					var pulled_dir = _get_valid_slide_dir(other, dir, pull_ignore, moving_objects)
					
					if pulled_dir == Vector2i.ZERO:
						continue # 无法分解，断开拉扯留置原地
						
					if moving_objects.has(other):
						if moving_objects[other] != pulled_dir:
							return {} # 拉扯方向冲突
					else:
						moving_objects[other] = pulled_dir
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
	if not enable:
		return false
	
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

	if not is_exploding and (to_radius < 1 or to_radius > 3):
		facing_cube.shake()
		return false
	
	var new_rect = facing_cube.get_rect(facing_cube.coordinate, to_radius)
	
	if not is_exploding:
		if new_rect.position.x < 0 or new_rect.position.y < 0 or new_rect.end.x > GameManager.WIDTH or new_rect.end.y > GameManager.HEIGHT:
			facing_cube.shake()
			return false

	var initial_moves = {}
	
	# ================= 膨胀产生的外推力 (Delta > 0) =================
	if delta > 0:
		for target in get_tree().get_nodes_in_group("OBJECT"):
			if target == facing_cube: continue
			var target_rect = target.get_rect()
			
			if new_rect.intersects(target_rect):
				if is_exploding:
					if target.type != GameManager.CONTENT.WALL and target.type != GameManager.CONTENT.CUBE_FIXED:
						initial_moves[target] = target.get_push_dir(facing_cube.coordinate)
				else:
					if target.type == GameManager.CONTENT.CUBE_FIXED or target.type == GameManager.CONTENT.WALL or facing_cube.mass < target.mass:
						facing_cube.shake()
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
				
				var intended_dir = -target.get_push_dir(facing_cube.coordinate)
				# 同样将 initial_moves 作为预判字典传入
				var valid_dir = _get_valid_slide_dir(target, intended_dir, [facing_cube], initial_moves)
				
				if valid_dir != Vector2i.ZERO:
					initial_moves[target] = valid_dir

	# 计算所有的后续连锁反应
	var moves = {}
	if not initial_moves.is_empty():
		moves = _calculate_kinematic_chain(initial_moves, [facing_cube])
		if moves.is_empty():
			if not is_exploding:
				facing_cube.shake()
				return false
			else:
				moves = {} 

	if not is_exploding:
		if not moves.is_empty():
			for m_obj in moves:
				var final_rect = m_obj.get_rect(m_obj.coordinate + moves[m_obj])
				if final_rect.intersects(new_rect):
					facing_cube.shake()
					return false
					
		for target in get_tree().get_nodes_in_group("OBJECT"):
			if target == facing_cube or moves.has(target): continue
			var target_rect = target.get_rect()
			if new_rect.intersects(target_rect):
				if not _can_overlap(facing_cube, target):
					facing_cube.shake()
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

	for item in get_tree().get_nodes_in_group("FIREBALL"):
		var is_finished = false
		for hole in get_tree().get_nodes_in_group("FIREPIT"):
			if item.coordinate == hole.coordinate:
				is_finished = true
				break
		if not is_finished:
			return true
	
	level_finished.emit()
	return true
