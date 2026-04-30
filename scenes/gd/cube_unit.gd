class_name CubeUnit extends Node2D

@export_category("Basic Properties")
@export var coordinate: Vector2i
@export var mass: int
@export var type: GameManager.CONTENT
@export var radius: int

@export var is_hint_enable := false
@export var is_fixed := false
var is_exploding: bool = false

var facing: Vector2i = Vector2i.DOWN
var _pos_tween: Tween
var _hint_tween: Tween
var _offset := Vector2i(32, 32)

@onready var Outlook = $HoverWrapper/Outlook
@onready var HoverWrapper = $HoverWrapper
@onready var Area = $Area2D

func _ready() -> void:
	position =  coordinate * 64 + _offset

func move_to(to_coordinate: Vector2i) -> bool:
	facing = sign(to_coordinate - coordinate)
	coordinate = to_coordinate
	
	var to_position = (coordinate) * 64 + Vector2i(32, 32)
	if _pos_tween:
		_pos_tween.kill()
	_pos_tween = get_tree().create_tween()
	_pos_tween.set_ease(Tween.EASE_OUT)
	_pos_tween.set_trans(Tween.TRANS_EXPO)
	_pos_tween.tween_property(self, "position", Vector2(to_position), GameManager.ANIMATION_TIME).set_delay(GameManager.TWEEN_TIME)
	return true

func get_rect(to_pos: Vector2i = coordinate, to_radius: int = radius) -> Rect2i:
	return Rect2i(to_pos-Vector2i(to_radius-1, to_radius-1), Vector2i(2*to_radius-1, 2*to_radius-1))

func get_push_dir(from_coord: Vector2i):
	var dx = coordinate.x - from_coord.x
	var dy = coordinate.y - from_coord.y
	if abs(dx) > abs(dy):
		return Vector2i(sign(dx), 0)
	elif abs(dy) > abs(dx):
		return Vector2i(0, sign(dy))
	else:
		return Vector2i(sign(dx), sign(dy))

func _on_mouse_entered():
	if is_hint_enable:
		play_hint(Vector2.ONE * 1.1)
		z_index += 99

func _on_mouse_exited():
	if is_hint_enable:
		play_hint(Vector2.ONE)
		z_index -= 99

func play_hint(to_scale: Vector2):
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = get_tree().create_tween()
	_hint_tween.set_trans(Tween.TRANS_CUBIC)
	_hint_tween.tween_property(HoverWrapper, "scale", to_scale, GameManager.TWEEN_TIME)

func shake():
	var shake_tween = get_tree().create_tween()
	
	shake_tween.tween_method(_random_offset.bind(HoverWrapper), 10, 0, 3*GameManager.TWEEN_TIME)
	shake_tween.tween_callback(func ():
		HoverWrapper.position = Vector2.ZERO
	)

func _random_offset(radius: float, obj: Object):
	if obj:
		obj.position = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
