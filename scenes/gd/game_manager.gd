extends Node

var is_editing: bool = true
var now_setting: CONTENT = CONTENT.CUBE_NORMAL
var is_dark_mode: bool = true
var now_mouse_click_mode: bool = true

const ANIMATION_SPEED := 1.0
const TWEEN_TIME := 0.1
const HEIGHT: int = 12
const WIDTH: int = 16

const RIGHT_POSITION = Vector2(512, 0)
const MIDDLE_POSITION = Vector2(288, 0)

var map_panel_size := Vector2.ZERO
var map_panel_position := Vector2.ZERO

enum CONTENT{
	CUBE_NORMAL,
	CUBE_STICKY,
	CUBE_FIXED,
	CUBE_BOOM,
	FIREBALL,
	FIREPIT,
	WALL
}

enum DIRECTION{
	UP,
	RIGHT,
	DOWN,
	LEFT
}

func shake(obj):
	if obj:
		var shake_tween = get_tree().create_tween()
		
		shake_tween.tween_method(_random_offset.bind(obj, obj.position), 10, 0, 0.6)
		shake_tween.tween_callback(func ():
			if obj:
				obj.position = (Vector2(obj.coordinate)) * 64 + Vector2(32, 32))

func _random_offset(radius: float, obj: Object, origin: Vector2):
	if obj:
		obj.position = origin + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
