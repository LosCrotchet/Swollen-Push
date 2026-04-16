class_name CubeUnit extends Node2D

@export_category("Basic Properties")
@export var coordinate: Vector2i
@export var mass: int
@export var type: GameManager.CONTENT
@export var radius: int

var is_exploding: bool = false

var facing: Vector2i = Vector2i.DOWN
var _pos_tween: Tween
var _offset := Vector2i(32, 32)

func _init(_coordinate: Vector2i, _mass: int, _type: GameManager.CONTENT, _radius: int = 1):
	coordinate = _coordinate
	mass = _mass
	type = _type
	radius = _radius
	
	position =  _coordinate * 64 + _offset
	
	var Outlook = Sprite2D.new()
	Outlook.name = "Outlook"
	Outlook.set_texture(load("res://assets/textures.png"))
	Outlook.region_enabled = true
	Outlook.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(Outlook)
	
	var AnimatedOutlook = AnimatedSprite2D.new()
	AnimatedOutlook.name = "AnimatedOutlook"
	add_child(AnimatedOutlook)

func move_to(to_coordinate: Vector2i) -> bool:
	facing = sign(to_coordinate - coordinate)
	coordinate = to_coordinate
	
	var to_position = (coordinate) * 64 + Vector2i(32, 32)
	if _pos_tween:
		_pos_tween.kill()
	_pos_tween = get_tree().create_tween()
	_pos_tween.set_ease(Tween.EASE_OUT)
	_pos_tween.set_trans(Tween.TRANS_CUBIC)
	_pos_tween.tween_property(self, "position", Vector2(to_position), GameManager.TWEEN_TIME).set_delay(2*GameManager.TWEEN_TIME)
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
