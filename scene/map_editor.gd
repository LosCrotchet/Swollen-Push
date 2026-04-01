extends Control

const TEXTURES = preload("res://assets/textures.tres")
const CUBE = preload("res://scene/cube.tscn")
const BOX = preload("res://scene/box.tscn")
const WALL = preload("res://scene/wall.tscn")
const HOLE = preload("res://scene/hole.tscn")

const OFFSET = Vector2(32, 32)

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
			if event.is_action_pressed("mouse_right"):
				GridManager.update_cube(mouse_coord, -1)


func create(what: GameManager.CONTENT, coord: Vector2i):
	if what == GameManager.CONTENT.HOLE:
		for item in get_tree().get_nodes_in_group("props"):
			if item.coordinate == Vector2(coord):
				return
	else:
		for item in get_tree().get_nodes_in_group("Objects"):
			if item.is_in_group("cubes") and item.has_point(coord):
				return
			if item.coordinate == Vector2(coord):
				return
	
	match what:
		GameManager.CONTENT.CUBE_SIMPLE,\
		GameManager.CONTENT.CUBE_STICKY,\
		GameManager.CONTENT.CUBE_STATIC:
			#GridManager.update_map(coord, _create_cube(coord, what))
			_create_cube(coord, what)
		GameManager.CONTENT.BOX:
			#GridManager.update_map(coord, _create_box(coord))
			_create_box(coord)
		GameManager.CONTENT.WALL:
			#GridManager.update_map(coord, _create_wall(coord))
			_create_wall(coord)
		GameManager.CONTENT.HOLE:
			#GridManager.update_props(coord, _create_hole(coord))
			_create_hole(coord)

func _create_cube(cube_coord: Vector2i, cube_type: GameManager.CONTENT = GameManager.CONTENT.CUBE_SIMPLE):
	
	for item in get_tree().get_nodes_in_group("cubes"):
		if item.has_point(cube_coord):
			item.remove_from_group("cubes")
			item.remove_from_group("Objects")
			item.queue_free()
			return
	
	var tmp_cube = CUBE.instantiate()
	tmp_cube.position = Vector2i(64, 64) + cube_coord * 64
	tmp_cube.coordinate = cube_coord
	tmp_cube.type = cube_type
	
	add_child(tmp_cube)
	
	tmp_cube.add_to_group("Objects")
	tmp_cube.add_to_group("cubes")
	
	return tmp_cube

func _create_box(box_coord: Vector2i):
	
	for item in get_tree().get_nodes_in_group("cubes"):
		if item.has_point(box_coord):
			return

	for item in get_tree().get_nodes_in_group("boxes"):
		if item.coordinate == Vector2(box_coord):
			item.remove_from_group("boxes")
			item.remove_from_group("Objects")
			item.queue_free()
			return
	
	var tmp_box = BOX.instantiate()
	tmp_box.position = Vector2i(64, 64) + box_coord * 64
	tmp_box.coordinate = box_coord
	
	add_child(tmp_box)
	
	tmp_box.add_to_group("Objects")
	tmp_box.add_to_group("boxes")
	
	return tmp_box

func _create_wall(wall_coord: Vector2i):
	
	for item in get_tree().get_nodes_in_group("cubes"):
		if item.has_point(wall_coord):
			return

	for item in get_tree().get_nodes_in_group("walls"):
		if item.coordinate == Vector2(wall_coord):
			item.remove_from_group("walls")
			item.remove_from_group("Objects")
			item.queue_free()
			return
	
	var tmp_wall = WALL.instantiate()
	tmp_wall.position = Vector2i(64, 64) + wall_coord * 64
	tmp_wall.coordinate = wall_coord
	
	add_child(tmp_wall)
	
	tmp_wall.add_to_group("Objects")
	tmp_wall.add_to_group("walls")
	
	return tmp_wall

func _create_hole(hole_coord: Vector2i):
	for item in get_tree().get_nodes_in_group("props"):
		if item.coordinate == Vector2(hole_coord):
			item.remove_from_group("props")
			item.queue_free()
			return
	
	var tmp_hole = HOLE.instantiate()
	tmp_hole.position = Vector2i(64, 64) + hole_coord * 64
	tmp_hole.coordinate = hole_coord
	tmp_hole.z_index = -10
	
	add_child(tmp_hole)
	
	tmp_hole.add_to_group("props")
	
	return tmp_hole

func delete(coord: Vector2i):
	for item in get_tree().get_nodes_in_group("Objects"):
		if item.is_in_group("cubes") and item.has_point(coord):
			item.remove_from_group("cubes")
			item.remove_from_group("Objects")
			item.queue_free()
			#GridManager.update_map(coord)
			return
		if item.coordinate == Vector2(coord):
			item.remove_from_group("boxes")
			item.remove_from_group("walls")
			item.remove_from_group("Objects")
			item.queue_free()
			#GridManager.update_map(coord)
			return
	for item in get_tree().get_nodes_in_group("props"):
		if item.coordinate == Vector2(coord):
			item.remove_from_group("props")
			item.queue_free()
			#GridManager.update_props(coord)
			return


func _on_reset_button_pressed() -> void:
	is_left_pressing = false
	is_right_pressing = false
	
	for item in get_tree().get_nodes_in_group("props"):
		item.queue_free()
	for item in get_tree().get_nodes_in_group("Objects"):
		if item.is_in_group("cubes") or item.is_in_group("boxes") or item.is_in_group("walls"):
			item.remove_from_group("Objects")
			item.remove_from_group("cubes")
			item.remove_from_group("walls")
			item.remove_from_group("boxes")
			item.queue_free()
	
	
