extends Node

var is_editing: bool = true
var now_setting: CONTENT = CONTENT.CUBE_SIMPLE
var is_dark_mode: bool = true
var now_mouse_click_mode: bool = true

const TWEEN_TIME := 0.1
const HEIGHT: int = 12
const WIDTH: int = 16

enum STATUE{
	NORMAL,
	INTERACTING,
	PASSIVE
}

enum CONTENT{
	CUBE_SIMPLE,
	CUBE_STICKY,
	CUBE_STATIC,
	WALL,
	BOX,
	HOLE,
	CUBE_V,
	CUBE_H
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
				obj.position = (Vector2(obj.coordinate) + Vector2(1, 1)) * 64)

func _random_offset(radius: float, obj: Object, origin: Vector2):
	if obj:
		obj.position = origin + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
