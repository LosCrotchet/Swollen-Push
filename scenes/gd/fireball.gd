extends CubeUnit
class_name FireBall

func _ready() -> void:
	z_index = 10
	Outlook.region_rect = Rect2(128, 128 if GameManager.is_dark_mode else 0, 64, 64)
	Outlook.visible = false
	
	AnimatedOutlook.scale = Vector2.ONE * 0.5
	AnimatedOutlook.sprite_frames = load("res://assets/tres/cube_frames.tres")
	AnimatedOutlook.animation = "fireball"
	AnimatedOutlook.play()
	
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
	_pos_tween.tween_property(self, "position", Vector2(to_position), GameManager.TWEEN_TIME).set_delay(2*GameManager.TWEEN_TIME)
	_pos_tween.tween_callback(func():
		rotation = -Vector2(facing).angle_to(Vector2.DOWN)
		).set_delay(2*GameManager.TWEEN_TIME)
	return true
