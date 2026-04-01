extends Node2D

@export var coordinate: Vector2
@export var radius: float = 1
@export var statue: GameManager.STATUE	# 用来提示当前状态，仅做外观变化
@export var mass: int = 100
@export var type: GameManager.CONTENT = GameManager.CONTENT.CUBE_SIMPLE

var cube_scale_tween
var pos_tween

func _ready() -> void:
	$Outlook.scale = Vector2(0.143+0.286*(radius-1), 0.143+0.286*(radius-1)) * 1.42
	
	match type:
		GameManager.CONTENT.CUBE_SIMPLE:
			$Outlook.region_rect = Rect2(258, 0, 448, 488)
		GameManager.CONTENT.CUBE_STICKY:
			$Outlook.region_rect = Rect2(704, 0, 448, 488)
		GameManager.CONTENT.CUBE_STATIC:
			$Outlook.region_rect = Rect2(1152, 0, 448, 488)

func has_point(pos: Vector2, set_radius: float = radius):
	return Rect2(coordinate-Vector2(set_radius-1, set_radius-1), Vector2(2*set_radius-1, 2*set_radius-1)).has_point(pos)

func _physics_process(delta: float) -> void:
	match statue:
		GameManager.STATUE.NORMAL:
			$Outlook.modulate = Color(1, 1, 1, 1)
		GameManager.STATUE.INTERACTING:
			$Outlook.modulate = Color(1.0, 0.75, 0.75, 1.0)
		GameManager.STATUE.PASSIVE:
			$Outlook.modulate = Color(0.75, 0.75, 1.0, 1.0)

func set_radius(to_radius: float):
	radius = to_radius
	var to_scale = Vector2(0.143+0.286*(radius-1), 0.143+0.286*(radius-1)) * 1.42
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
	
