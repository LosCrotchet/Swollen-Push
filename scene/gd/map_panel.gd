extends Panel

# 在你的原变量区域，替换掉 to_val 和 to_direction
var pos_tween: Tween
var box_pos_tween: Tween

const HEIGHT: int = 12
const WIDTH: int = 16

@onready var base: TileMapLayer = $Base
@onready var cursor: TileMapLayer = $Cursor

const TEXTURES = preload("res://assets/textures.tres")
const CUBE = preload("res://scene/cube.tscn")
const BOX = preload("res://scene/box.tscn")
const WALL = preload("res://scene/wall.tscn")

func _ready() -> void:
	cursor.clear()

func _physics_process(delta: float) -> void:
	if GameManager.is_editing:
		_update_cursor()
	
	_update_cube_pattern()
	
func _update_cube_pattern():
	var mouse_position = get_global_mouse_position()
	var grid_mouse_position = mouse_position - position - cursor.position
	
	if grid_mouse_position.x < 0 or grid_mouse_position.x >= WIDTH*64 or\
	grid_mouse_position.y < 0 or grid_mouse_position.y >= HEIGHT*64:
		cursor.clear()
		return
	
	@warning_ignore("integer_division")
	var mouse_coord = Vector2i(int(grid_mouse_position.x) / 64, int(grid_mouse_position.y) / 64)
	
	for item in get_tree().get_nodes_in_group("cubes"):
		item.statue = GameManager.STATUE.NORMAL
	
	var center = null
	for item in get_tree().get_nodes_in_group("cubes"):
		var cube_rect = item.get_rect()
		if cube_rect.has_point(mouse_coord):
			center = item
			item.statue = GameManager.STATUE.INTERACTING
			break
	
	if center:
		var cube_rect = center.get_rect(center.coordinate, center.radius+1)
		for item in get_tree().get_nodes_in_group("cubes"):
			if item == center:
				continue
			var item_rect = item.get_rect()
			if cube_rect.intersects(item_rect):
				item.statue = GameManager.STATUE.PASSIVE

func _update_cursor():
	var mouse_position = get_global_mouse_position()
	var grid_mouse_position = mouse_position - position - cursor.position
	
	if grid_mouse_position.x < 0 or grid_mouse_position.x >= WIDTH*64 or\
	grid_mouse_position.y < 0 or grid_mouse_position.y >= HEIGHT*64:
		cursor.clear()
		return
	
	@warning_ignore("integer_division")
	var grid_x = int(grid_mouse_position.x) / 64
	@warning_ignore("integer_division")
	var grid_y = int(grid_mouse_position.y) / 64
	
	cursor.clear()
	cursor.set_cell(Vector2i(grid_x, grid_y), 0, Vector2i(1, 4))


func _on_reset_button_pressed() -> void:
	cursor.clear()
