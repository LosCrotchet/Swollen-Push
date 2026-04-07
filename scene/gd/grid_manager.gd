extends Node

# 辅助函数：获取物体在网格上占据的包围盒
func get_grid_rect(coord: Vector2, radius: int = 1) -> Rect2:
	return Rect2(coord - Vector2(radius - 1, radius - 1), Vector2(2 * radius - 1, 2 * radius - 1))

# 辅助函数：防止数组越界
func is_in_bounds(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < GameManager.WIDTH and coord.y < GameManager.HEIGHT

# 辅助函数：计算推/拉方向
func get_push_dir(from_coord: Vector2, to_coord: Vector2) -> Vector2:
	var dx = to_coord.x - from_coord.x
	var dy = to_coord.y - from_coord.y
	if abs(dx) > abs(dy):
		return Vector2(sign(dx), 0)
	elif abs(dy) > abs(dx):
		return Vector2(0, sign(dy))
	else:
		return Vector2(sign(dx), sign(dy))

# ==========================================
# 核心引擎：计算所有连带运动并验证 (BFS 算法)
# 能够正确处理黏性方块的无限连带
# 返回字典 { object: Vector2(dir) }，如果失败则返回空字典 {}
# ==========================================
func calculate_movement(initial_moves: Dictionary, ignore_objects: Array = []) -> Dictionary:
	var moving_objects = {}
	var queue = []

	# 初始化施力源
	for obj in initial_moves:
		moving_objects[obj] = initial_moves[obj]
		queue.append(obj)

	# 1. 广度优先遍历所有受波及的物体
	while queue.size() > 0:
		var curr = queue.pop_front()
		var dir = moving_objects[curr]
		#var curr_r = curr.radius if curr.is_in_group("cubes") else 1
		var curr_rect = curr.get_rect()
		var next_rect = curr.get_rect(curr.coordinate + dir)
		
		for other in get_tree().get_nodes_in_group("Objects"):
			if other == curr or other in ignore_objects:
				continue
			
			#var other_r = other.radius if other.is_in_group("cubes") else 1
			var other_rect = other.get_rect()
			
			var is_pushed = next_rect.intersects(other_rect)
			
			# 【关键修复】：如果 other 已经被带着一起同向移动了，说明它会让出当前格子。
			# 这属于“跟随/补位”而不是“推挤”，此时应该免除物理推挤的质量校验。
			if is_pushed and moving_objects.has(other) and moving_objects[other] == dir:
				is_pushed = false
			
			var is_stuck = false
			
			if not is_pushed:
				# 判断当前是否贴在一起（将包围盒上下左右各扩张一格来模拟相邻检测）
				var expanded_curr = Rect2(curr_rect.position - Vector2(1, 1), curr_rect.size + Vector2(2, 2))
				if expanded_curr.intersects(other_rect) and not curr_rect.intersects(other_rect):
					var curr_sticky = (curr.is_in_group("cubes") and curr.type == GameManager.CONTENT.CUBE_STICKY)
					var other_sticky = (other.is_in_group("cubes") and other.type == GameManager.CONTENT.CUBE_STICKY)
					if curr_sticky or other_sticky:
						is_stuck = true
						
			if is_pushed or is_stuck:
				var is_immovable = (other.type == GameManager.CONTENT.WALL or other.type == GameManager.CONTENT.CUBE_STATIC)
				if is_immovable:
					if is_pushed:
						return {} # 推不动死物，整个运动崩溃并失败
					else:
						continue  # 黏性方块拉不动死物，但死物也不会阻止方块移动，跳过即可
						
				if is_pushed and curr.mass < other.mass:
					return {} # 质量不足，推不动
				elif is_stuck and curr.mass < other.mass:
					continue # 被粘带的物体太重，拉不动，直接断开粘连但不算失败
					
				if moving_objects.has(other):
					if moving_objects[other] != dir:
						return {} # 同一个物体被多个不同方向力作用，发生挤压/拉扯，运动失败
				else:
					moving_objects[other] = dir
					queue.append(other)

	# 2. 验证阶段：所有的终点是否合法
	var target_rects = []
	for obj in moving_objects:
		#var r = obj.radius if obj.is_in_group("cubes") else 1
		var final_rect = obj.get_rect(obj.coordinate + moving_objects[obj])
		
		# 越界验证
		if final_rect.position.x < 0 or final_rect.position.y < 0 or final_rect.end.x > GameManager.WIDTH or final_rect.end.y > GameManager.HEIGHT:
			return {}
		target_rects.append({ "obj": obj, "rect": final_rect })

	# 3. 重叠验证
	for i in range(target_rects.size()):
		for j in range(i + 1, target_rects.size()):
			if target_rects[i]["rect"].intersects(target_rects[j]["rect"]):
				return {} # 多个运动物体的终点轨迹互相重叠冲突
				
		for other in get_tree().get_nodes_in_group("Objects"):
			if other in moving_objects or other in ignore_objects:
				continue
			#var other_r = other.radius if other.is_in_group("cubes") else 1
			var other_rect = other.get_rect()
			if target_rects[i]["rect"].intersects(other_rect):
				return {} # 运动中的物体终点撞到了完全没有运动的物体
				
	return moving_objects

# ==========================================
# 核心互动：更新球体与膨胀检测
# ==========================================
func update_cube(coord: Vector2i, delta: int = 1):
	var facing_cube = null
	for item in get_tree().get_nodes_in_group("cubes"):
		if item.has_point(coord):
			facing_cube = item
			break
	if not facing_cube:
		return false
	
	var origin_radius = facing_cube.radius
	var to_radius = origin_radius + delta

	if to_radius < 1 or to_radius > 3:
		GameManager.shake(facing_cube)
		return false
	
	# 1. 验证膨胀自身不越界
	var new_rect = facing_cube.get_rect(facing_cube.coordinate, to_radius)
	if new_rect.position.x < 0 or new_rect.position.y < 0 or new_rect.end.x > GameManager.WIDTH or new_rect.end.y > GameManager.HEIGHT:
		GameManager.shake(facing_cube)
		return false
		
	var initial_moves = {}
	
	# ================= 膨胀产生的外推力 (Delta > 0) =================
	if delta > 0:
		for target in get_tree().get_nodes_in_group("Objects"):
			if target == facing_cube: continue
			
			#var target_r = target.radius if target.is_in_group("cubes") else 1
			var target_rect = target.get_rect()
			
			if new_rect.intersects(target_rect):
				# 质量或类型特判
				if target.type == GameManager.CONTENT.CUBE_STATIC or target.type == GameManager.CONTENT.WALL:
					GameManager.shake(facing_cube)
					return false
				if facing_cube.mass < target.mass:
					GameManager.shake(facing_cube)
					return false
				# 计算被推开的方向
				initial_moves[target] = get_push_dir(facing_cube.coordinate, target.coordinate)

	# ================= 收缩产生的内拉力 (Delta < 0) =================
	elif delta < 0:
		var old_rect = facing_cube.get_rect(facing_cube.coordinate, origin_radius)
		for target in get_tree().get_nodes_in_group("Objects"):
			if target == facing_cube: continue
			
			#var target_r = target.radius if target.is_in_group("cubes") else 1
			var target_rect = target.get_rect()
			
			if facing_cube.type != GameManager.CONTENT.CUBE_STICKY and target.type != GameManager.CONTENT.CUBE_STICKY:
				continue
				
			var expanded_old = Rect2(old_rect.position - Vector2(1,1), old_rect.size + Vector2(2,2))
			if expanded_old.intersects(target_rect) and not old_rect.intersects(target_rect):
				if target.type == GameManager.CONTENT.CUBE_STATIC or target.type == GameManager.CONTENT.WALL:
					continue
				if facing_cube.mass < target.mass:
					continue
				# 拉扯方向是从目标指向中心方块
				initial_moves[target] = get_push_dir(target.coordinate, facing_cube.coordinate)

	# 计算所有的后续连锁反应
	var moves = {}
	if not initial_moves.is_empty():
		moves = calculate_movement(initial_moves, [facing_cube])
		if moves.is_empty():
			GameManager.shake(facing_cube)
			return false
		# 额外检查：由于中心方块膨胀了，移动后的物体会不会撞到膨胀后新体积的中心方块
		for m_obj in moves:
			#var r = m_obj.radius if m_obj.is_in_group("cubes") else 1
			var final_rect = m_obj.get_rect(m_obj.coordinate + moves[m_obj])
			if final_rect.intersects(new_rect):
				GameManager.shake(facing_cube)
				return false
				
	# 最后兜底检查：膨胀的新体积本身会不会压到未被推动的物体
	for target in get_tree().get_nodes_in_group("Objects"):
		if target == facing_cube: continue
		if moves.has(target): continue
		#var target_r = target.radius if target.is_in_group("cubes") else 1
		var target_rect = target.get_rect()
		if new_rect.intersects(target_rect):
			GameManager.shake(facing_cube)
			return false

	# 3. 落实表现与移动
	facing_cube.set_radius(to_radius)
	for obj in moves:
		if obj.has_method("move_to"):
			obj.move_to(obj.coordinate + moves[obj])
			
	return true

# ==========================================
# 替换原 attemp_move：外部调用推箱子接口
# 包含验证并直接执行除 obj 本身外的所有附带运动
# ==========================================
func attemp_move(obj, dir: Vector2) -> bool:
	var moves = calculate_movement({obj: dir})
	if moves.is_empty():
		return false
		
	# 执行连带运动（通常 obj 是老鼠，会在自己的输入判定里做位移，所以此处排除了 obj 本身）
	for m_obj in moves:
		if m_obj != obj:
			if m_obj.has_method("move_to"):
				m_obj.move_to(m_obj.coordinate + moves[m_obj])
	return true
