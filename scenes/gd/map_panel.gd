extends Panel

# 在你的原变量区域，替换掉 to_val 和 to_direction
var pos_tween: Tween
var box_pos_tween: Tween

const HEIGHT: int = 12
const WIDTH: int = 16

@onready var base: TileMapLayer = $Base
@onready var cursor: TileMapLayer = $Cursor

func _ready() -> void:
	cursor.clear()

func _physics_process(delta: float) -> void:
	if GameManager.is_editing:
		_update_cursor()
	

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
	for item in get_tree().get_nodes_in_group("WALL"):
		if item.coordinate == Vector2i(grid_x, grid_y):
			return
	
	cursor.set_cell(Vector2i(grid_x, grid_y), 0, Vector2i(4, 0))


func _on_reset_button_pressed() -> void:
	base.position = Vector2.ZERO
	base.clear()
	for i in range(GameManager.WIDTH):
		for j in range(GameManager.HEIGHT):
			base.set_cell(Vector2i(i, j), 1, Vector2i(0, 0))
	cursor.position = Vector2.ZERO
	$MapEditor.position = Vector2.ZERO
	cursor.clear()
