extends Node2D

@export var coordinate: Vector2
@export var radius: float = 1
@export var statue: GameManager.STATUE	# 用来提示当前状态，仅做外观变化
@export var mass: int = 100
@export var type: GameManager.CONTENT = GameManager.CONTENT.CUBE_SIMPLE

var cube_scale_tween
var pos_tween

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

func has_point(pos: Vector2, set_radius: float = radius):
	if type == GameManager.CONTENT.CUBE_V:
		return Rect2(coordinate-Vector2(0, set_radius-1), Vector2(1, 2*set_radius-1)).has_point(pos)
	if type == GameManager.CONTENT.CUBE_H:
		return Rect2(coordinate-Vector2(set_radius-1, 0), Vector2(2*set_radius-1, 1)).has_point(pos)
	return Rect2(coordinate-Vector2(set_radius-1, set_radius-1), Vector2(2*set_radius-1, 2*set_radius-1)).has_point(pos)

func get_rect(to_pos: Vector2 = coordinate, to_radius: float = radius):
	if type == GameManager.CONTENT.CUBE_V:
		return Rect2(to_pos-Vector2(0, to_radius-1), Vector2(1, 2*to_radius-1))
	if type == GameManager.CONTENT.CUBE_H:
		return Rect2(to_pos-Vector2(to_radius-1, 0), Vector2(2*to_radius-1, 1))
	return Rect2(to_pos-Vector2(to_radius-1, to_radius-1), Vector2(2*to_radius-1, 2*to_radius-1))


func _physics_process(delta: float) -> void:
	match statue:
		GameManager.STATUE.NORMAL:
			$Outlook.modulate = Color(1, 1, 1, 1)
		GameManager.STATUE.INTERACTING:
			$Outlook.modulate = Color(1.0, 0.65, 0.65, 1.0)
		GameManager.STATUE.PASSIVE:
			$Outlook.modulate = Color(0.65, 0.65, 1.0, 1.0)

func set_radius(to_radius: float):
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

func move_to(to_coordinate: Vector2):
	coordinate = to_coordinate
	var to_position = (coordinate + Vector2(1, 1)) * 64
	if pos_tween:
		pos_tween.kill()
	pos_tween = get_tree().create_tween()
	pos_tween.set_ease(Tween.EASE_OUT)
	pos_tween.set_trans(Tween.TRANS_CUBIC)
	pos_tween.tween_property(self, "position", to_position, GameManager.TWEEN_TIME)
	
