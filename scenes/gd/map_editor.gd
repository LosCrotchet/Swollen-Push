extends Control

const OFFSET = Vector2.ZERO

var is_left_pressing: bool = false
var is_right_pressing: bool = false

@onready var CUBE = preload("res://scenes/cube.tscn")
@onready var FIREBALL = preload("res://scenes/fireball.tscn")
@onready var FIREPIT = preload("res://scenes/firepit.tscn")
@onready var WALL = preload("res://scenes/wall.tscn")

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
				GridManager.apply_cube_scaling(mouse_coord, 1)
				#if OS.has_feature("android") and not GameManager.now_mouse_click_mode:
				#	GridManager.apply_cube_scaling(mouse_coord, -1)
			if event.is_action_pressed("mouse_right"):
				GridManager.apply_cube_scaling(mouse_coord, -1)
			

func create(what: GameManager.CONTENT, coord: Vector2i, radius: int = 1):
	for item in get_tree().get_nodes_in_group("OBJECT"):
		if item.get_rect().has_point(coord):
			return null
	
	match what:
		GameManager.CONTENT.CUBE_NORMAL,\
		GameManager.CONTENT.CUBE_STICKY,\
		GameManager.CONTENT.CUBE_FIXED,\
		GameManager.CONTENT.CUBE_BOOM:
			return _create_cube(coord, radius, what)
		GameManager.CONTENT.FIREBALL:
			return _create_fireball(coord)
		GameManager.CONTENT.WALL:
			return _create_wall(coord)
		GameManager.CONTENT.FIREPIT:
			return _create_firepit(coord)
	
	#SaveAndLoad._on_save_button_pressed()
	
	return null

func _create_cube(coord: Vector2i, radius: int, type: GameManager.CONTENT):
	for item in get_tree().get_nodes_in_group("CUBE"):
		if item.get_rect().has_point(coord):
			item.remove_from_group("CUBE")
			item.remove_from_group("OBJECT")
			item.queue_free()
			return null
	
	
	var tmp: Cube = CUBE.instantiate()
	tmp.type = type
	tmp.radius = radius
	tmp.coordinate = coord
	tmp.mass = 100
	#var tmp_cube = CUBE.instantiate()
	add_child(tmp)
	
	tmp.add_to_group("OBJECT")
	tmp.add_to_group("CUBE")
	
	return tmp

func _create_fireball(coord: Vector2i):
	for item in get_tree().get_nodes_in_group("CUBE"):
		if item.get_rect().has_point(coord):
			return null

	for item in get_tree().get_nodes_in_group("FIREBALL"):
		if item.coordinate == coord:
			item.remove_from_group("FIREBALL")
			item.remove_from_group("OBJECT")
			item.queue_free()
			return null
	
	var tmp: FireBall = FIREBALL.instantiate()
	tmp.type = GameManager.CONTENT.FIREBALL
	tmp.radius = 1
	tmp.coordinate = coord
	tmp.mass = 1
	#var tmp_cube = CUBE.instantiate()
	add_child(tmp)
	
	tmp.add_to_group("OBJECT")
	tmp.add_to_group("FIREBALL")
	
	return tmp

func _create_wall(coord: Vector2i):
	for item in get_tree().get_nodes_in_group("CUBE"):
		if item.get_rect().has_point(coord):
			return null

	for item in get_tree().get_nodes_in_group("WALL"):
		if item.coordinate == coord:
			item.remove_from_group("WALL")
			item.remove_from_group("OBJECT")
			item.queue_free()
			return null
	
	var tmp: Wall = WALL.instantiate()
	tmp.type = GameManager.CONTENT.WALL
	tmp.radius = 1
	tmp.coordinate = coord
	tmp.mass = 0x7fffffff
	#var tmp_cube = CUBE.instantiate()
	add_child(tmp)
	
	tmp.add_to_group("OBJECT")
	tmp.add_to_group("WALL")
	
	return tmp

func _create_firepit(coord: Vector2i):
	for item in get_tree().get_nodes_in_group("CUBE"):
		if item.get_rect().has_point(coord):
			return null
	for item in get_tree().get_nodes_in_group("FIREPIT"):
		if item.coordinate == coord:
			item.remove_from_group("FIREPIT")
			item.remove_from_group("OBJECT")
			item.queue_free()
			return null
	
	var tmp: FirePit = FIREPIT.instantiate()
	tmp.type = GameManager.CONTENT.FIREPIT
	tmp.radius = 1
	tmp.coordinate = coord
	tmp.mass = 1
	#var tmp_cube = CUBE.instantiate()
	add_child(tmp)
	
	tmp.add_to_group("OBJECT")
	tmp.add_to_group("FIREPIT")
	
	return tmp

func delete(coord: Vector2i) -> bool:
	for item in get_tree().get_nodes_in_group("OBJECT"):
		if item.get_rect().has_point(coord):
			item.remove_from_group("CUBE")
			item.remove_from_group("FIREBALL")
			item.remove_from_group("WALL")
			item.remove_from_group("FIREPIT")
			item.remove_from_group("OBJECT")
			item.queue_free()
			
			#SaveAndLoad._on_save_button_pressed()
			
			return true
	return false

func _on_reset_button_pressed() -> void:
	is_left_pressing = false
	is_right_pressing = false
	GridManager.enable = true

	for item in get_tree().get_nodes_in_group("OBJECT"):
		item.remove_from_group("OBJECT")
		item.remove_from_group("CUBE")
		item.remove_from_group("WALL")
		item.remove_from_group("FIREBALL")
		item.remove_from_group("FIREPIT")
		item.queue_free()
	
	
