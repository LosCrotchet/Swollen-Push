extends Control

const OFFSET = Vector2.ZERO

var is_left_pressing: bool = false
var is_right_pressing: bool = false

func _input(event: InputEvent) -> void:
	if GameManager.is_editing:
		if event.is_action_pressed("mouse_left"):
			is_left_pressing = true
		if event.is_action_released("mouse_left"):
			is_left_pressing = false
		if event.is_action_pressed("mouse_right"):
			is_right_pressing = true
		if event.is_action_released("mouse_right"):
			is_right_pressing = false
		
		#if OS.has_feature("android"):
		#	if not GameManager.now_mouse_click_mode:
		#		is_right_pressing = is_left_pressing
		#		is_left_pressing = false
		#	else:
		#		is_right_pressing = false
		
		var mouse_position = get_local_mouse_position()
		var grid_mouse_position = mouse_position - OFFSET
		
		if grid_mouse_position.x >= 0 and grid_mouse_position.x < GameManager.WIDTH*64 and\
		grid_mouse_position.y >= 0 and grid_mouse_position.y < GameManager.HEIGHT*64:
			@warning_ignore("integer_division")
			var grid_x = int(grid_mouse_position.x) / 64
			@warning_ignore("integer_division")
			var grid_y = int(grid_mouse_position.y) / 64
			
			if is_left_pressing:
				create(GameManager.now_setting ,Vector2i(grid_x, grid_y))
			if is_right_pressing:
				delete(Vector2i(grid_x, grid_y))	
	else:
		is_left_pressing = false
		is_right_pressing = false
		
		var mouse_position = get_local_mouse_position()
		var grid_mouse_position = mouse_position - OFFSET
		
		if grid_mouse_position.x >= 0 and grid_mouse_position.x < GameManager.WIDTH*64 and\
		grid_mouse_position.y >= 0 and grid_mouse_position.y < GameManager.HEIGHT*64:
			@warning_ignore("integer_division")
			var mouse_coord = Vector2i(int(grid_mouse_position.x) / 64, int(grid_mouse_position.y) / 64)
		
			if event.is_action_pressed("mouse_left"):
				GridManager.update_cube(mouse_coord, 1)
				#if OS.has_feature("android") and not GameManager.now_mouse_click_mode:
				#	GridManager.update_cube(mouse_coord, -1)
			if event.is_action_pressed("mouse_right"):
				GridManager.update_cube(mouse_coord, -1)
			

func create(what: GameManager.CONTENT, coord: Vector2i, radius: int = 1):
	if what == GameManager.CONTENT.HOLE:
		for item in get_tree().get_nodes_in_group("props"):
			if item.coordinate == coord:
				return null
	else:
		for item in get_tree().get_nodes_in_group("Objects"):
			if item.get_rect().has_point(coord):
				return null
	
	match what:
		GameManager.CONTENT.CUBE_SIMPLE,\
		GameManager.CONTENT.CUBE_STICKY,\
		GameManager.CONTENT.CUBE_STATIC,\
		GameManager.CONTENT.CUBE_BOOM:
			return _create_cube(coord, radius, what)
		GameManager.CONTENT.BOX:
			return _create_box(coord)
		GameManager.CONTENT.WALL:
			return _create_wall(coord)
		GameManager.CONTENT.HOLE:
			return _create_hole(coord)
	
	return null

func _create_cube(cube_coord: Vector2i, set_radius: int, cube_type: GameManager.CONTENT):
	for item in get_tree().get_nodes_in_group("cubes"):
		if item.get_rect().has_point(cube_coord):
			item.remove_from_group("cubes")
			item.remove_from_group("Objects")
			item.queue_free()
			return null
	
	
	var tmp_cube = Cube.new(cube_coord, 100, cube_type, set_radius)
	#var tmp_cube = CUBE.instantiate()
	add_child(tmp_cube)
	
	tmp_cube.add_to_group("Objects")
	tmp_cube.add_to_group("cubes")
	
	return tmp_cube

func _create_box(box_coord: Vector2i):
	for item in get_tree().get_nodes_in_group("cubes"):
		if item.get_rect().has_point(box_coord):
			return null

	for item in get_tree().get_nodes_in_group("boxes"):
		if item.coordinate == box_coord:
			item.remove_from_group("boxes")
			item.remove_from_group("Objects")
			item.queue_free()
			return null
	
	var tmp_box = Box.new(box_coord, 10, GameManager.CONTENT.BOX)
	add_child(tmp_box)
	
	tmp_box.add_to_group("Objects")
	tmp_box.add_to_group("boxes")
	
	return tmp_box

func _create_wall(wall_coord: Vector2i):
	for item in get_tree().get_nodes_in_group("cubes"):
		if item.get_rect().has_point(wall_coord):
			return null

	for item in get_tree().get_nodes_in_group("walls"):
		if item.coordinate == wall_coord:
			item.remove_from_group("walls")
			item.remove_from_group("Objects")
			item.queue_free()
			return null
	
	var tmp_wall = Wall.new(wall_coord, 0x7fffffff, GameManager.CONTENT.WALL)
	add_child(tmp_wall)
	
	tmp_wall.add_to_group("Objects")
	tmp_wall.add_to_group("walls")
	
	return tmp_wall

func _create_hole(hole_coord: Vector2i):
	for item in get_tree().get_nodes_in_group("props"):
		if item.coordinate == hole_coord:
			item.remove_from_group("props")
			item.queue_free()
			return null
	
	var tmp_hole = Hole.new(hole_coord, 0, GameManager.CONTENT.HOLE)
	#tmp_hole.z_index = -10
	add_child(tmp_hole)
	
	tmp_hole.add_to_group("props")
	
	return tmp_hole

func delete(coord: Vector2i) -> bool:
	for item in get_tree().get_nodes_in_group("Objects"):
		if item.get_rect().has_point(coord):
			item.remove_from_group("cubes")
			item.remove_from_group("boxes")
			item.remove_from_group("walls")
			item.remove_from_group("Objects")
			item.queue_free()
			return true
	for item in get_tree().get_nodes_in_group("props"):
		if item.coordinate == coord:
			item.remove_from_group("props")
			item.queue_free()
			return true
	return false

func _on_reset_button_pressed() -> void:
	is_left_pressing = false
	is_right_pressing = false
	
	for item in get_tree().get_nodes_in_group("props"):
		item.remove_from_group("props")
		item.queue_free()
	for item in get_tree().get_nodes_in_group("Objects"):
		item.remove_from_group("Objects")
		item.remove_from_group("cubes")
		item.remove_from_group("walls")
		item.remove_from_group("boxes")
		item.queue_free()
	
	
