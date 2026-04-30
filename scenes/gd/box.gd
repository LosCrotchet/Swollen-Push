extends CubeUnit
class_name Box

func _ready() -> void:
	z_index = 10
	
	Area.scale = Vector2(0.5, 0.5)
	Outlook.visible = true
	Outlook.region_rect = Rect2(128, 0, 64, 64)
	
	super._ready()

func move_to(to_coordinate: Vector2i) -> bool:
	facing = sign(to_coordinate - coordinate)
	coordinate = to_coordinate
	
	var to_position = (coordinate) * 64 + Vector2i(32, 32)
	if _pos_tween:
		_pos_tween.kill()
	_pos_tween = get_tree().create_tween().set_parallel()
	_pos_tween.set_ease(Tween.EASE_OUT)
	_pos_tween.set_trans(Tween.TRANS_CUBIC)
	_pos_tween.tween_property(self, "position", Vector2(to_position), GameManager.ANIMATION_TIME).set_delay(GameManager.TWEEN_TIME)
	
	return true
