extends CubeUnit
class_name FireBall

@onready var point_light_2d: PointLight2D = $PointLight2D

func _ready() -> void:
	z_index = 11
	#Outlook.region_rect = Rect2(128, 128 if GameManager.is_dark_mode else 0, 64, 64)
	Outlook.visible = false
	AnimatedOutlook.sprite_frames = load("res://assets/tres/cube_frames.tres")
	AnimatedOutlook.animation = "fireball"
	AnimatedOutlook.play()
	
	#Area.scale = Vector2(0.5, 0.5)
	#Outlook.visible = true
	#AnimatedOutlook.visible = false
	#Outlook.region_rect = Rect2(128, 128 if GameManager.is_dark_mode else 0, 64, 64)
	
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
	_pos_tween.tween_callback(func():
		rotation = -Vector2(facing).angle_to(Vector2.DOWN)
	).set_delay(2*GameManager.TWEEN_TIME)
	return true

func _on_light_shake_timer_timeout() -> void:
	point_light_2d.energy = randf_range(4.5, 5.5)
	point_light_2d.offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
