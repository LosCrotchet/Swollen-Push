extends CubeUnit
class_name Cube

@export var statue: GameManager.STATUE = GameManager.STATUE.NORMAL	# 用来提示当前状态，仅做外观变化

var cube_scale_tween: Tween

func _ready() -> void:
	$Outlook.scale = Vector2.ONE * ((radius - 1) * 2 + 1)
	
	match type:
		GameManager.CONTENT.CUBE_SIMPLE:
			$Outlook.region_rect = Rect2(0, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_STICKY:
			$Outlook.region_rect = Rect2(64, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_STATIC:
			$Outlook.region_rect = Rect2(128, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_V:
			$Outlook.region_rect = Rect2(256, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_H:
			$Outlook.region_rect = Rect2(192, 192 if GameManager.is_dark_mode else 64, 64, 64)

func has_point(pos: Vector2i, set_radius: int = radius) -> bool:
	if type == GameManager.CONTENT.CUBE_V:
		return Rect2i(coordinate-Vector2i(0, set_radius-1), Vector2i(1, 2*set_radius-1)).has_point(pos)
	if type == GameManager.CONTENT.CUBE_H:
		return Rect2i(coordinate-Vector2i(set_radius-1, 0), Vector2i(2*set_radius-1, 1)).has_point(pos)
	return Rect2i(coordinate-Vector2i(set_radius-1, set_radius-1), Vector2i(2*set_radius-1, 2*set_radius-1)).has_point(pos)

func get_rect(to_pos: Vector2i = coordinate, to_radius: int = radius):
	if type == GameManager.CONTENT.CUBE_V:
		return Rect2i(to_pos-Vector2i(0, to_radius-1), Vector2i(1, 2*to_radius-1))
	if type == GameManager.CONTENT.CUBE_H:
		return Rect2i(to_pos-Vector2i(to_radius-1, 0), Vector2i(2*to_radius-1, 1))
	return Rect2i(to_pos-Vector2i(to_radius-1, to_radius-1), Vector2i(2*to_radius-1, 2*to_radius-1))

func get_push_dir(from_coord: Vector2i):
	var dx = coordinate.x - from_coord.x
	var dy = coordinate.y - from_coord.y
	
	if type == GameManager.CONTENT.CUBE_V:
		for i in range(-radius+1, radius):
			if abs(dy) > abs(coordinate.y + i - from_coord.y):
				dy = coordinate.y + i - from_coord.y
	if type == GameManager.CONTENT.CUBE_H:
		for i in range(-radius+1, radius):
			if abs(dx) > abs(coordinate.x + i - from_coord.x):
				dx = coordinate.x + i - from_coord.x
	
	if abs(dx) > abs(dy):
		return Vector2i(sign(dx), 0)
	elif abs(dy) > abs(dx):
		return Vector2i(0, sign(dy))
	else:
		return Vector2i(sign(dx), sign(dy))

func set_statue(to_statue: GameManager.STATUE):
	statue = to_statue
	
	match statue:
		GameManager.STATUE.NORMAL:
			$Outlook.modulate = Color(1, 1, 1, 1)
		GameManager.STATUE.INTERACTING:
			$Outlook.modulate = Color(1.0, 0.65, 0.65, 1.0)
		GameManager.STATUE.PASSIVE:
			$Outlook.modulate = Color(0.65, 0.65, 1.0, 1.0)

func set_radius(to_radius: int) -> bool:
	if to_radius < 1:
		return false
	
	radius = to_radius
	
	var to_scale = Vector2.ONE * ((radius - 1) * 2 + 1)
	if type == GameManager.CONTENT.CUBE_V:
		to_scale.x = 1
	if type == GameManager.CONTENT.CUBE_H:
		to_scale.y = 1
	
	if cube_scale_tween:
		cube_scale_tween.kill()
	cube_scale_tween = get_tree().create_tween()
	cube_scale_tween.set_ease(Tween.EASE_OUT)
	cube_scale_tween.set_trans(Tween.TRANS_CIRC)
	cube_scale_tween.tween_property($Outlook, "scale", to_scale, GameManager.TWEEN_TIME)
	return true
