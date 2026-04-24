extends Node2D

@onready var animated_outlook: AnimatedSprite2D = $AnimatedOutlook
#@onready var animated_outlook_shadow: AnimatedSprite2D = $AnimatedOutlookShadow

@export var map_editor: Control
@export var type: String
@export var enable = true

# 配置参数
var SCREEN_SIZE = Vector2(1600, 900)
const PREFER_ZONE_WIDTH = 250.0
const PREFER_PROBABILITY = 0.6
const MOVE_SPEED = 120.0        # 移动速度

var speed_float = 1
var target_position = Vector2.ZERO
var is_moving = false
var is_dragging = false

var real_type: GameManager.CONTENT

func _ready():
	animated_outlook.play(type+"_walk")
	animated_outlook.frame = randi_range(0, animated_outlook.sprite_frames.get_frame_count(type+"_walk"))
	
	# 初始位置设为屏幕右侧或左侧
	if randf() < 0.5:
		position = Vector2(randf_range(SCREEN_SIZE.x - PREFER_ZONE_WIDTH, SCREEN_SIZE.x), randf_range(0, SCREEN_SIZE.y))
	else:
		position = Vector2(randf_range(0, PREFER_ZONE_WIDTH), randf_range(0, SCREEN_SIZE.y))
	_pick_new_target()
	
	$Outlook.modulate = Color(1, 1, 1, 0)
	$Outlook.scale = Vector2(0.01, 0.01)
	$Outlook.global_rotation_degrees = 720
	animated_outlook.set_instance_shader_parameter("enable", false)
	#animated_outlook.material.set_shader_parameter("enable", false)
	
	SCREEN_SIZE = get_window().size

	match type:
		"normal":
			real_type = GameManager.CONTENT.CUBE_NORMAL
		"sticky":
			real_type = GameManager.CONTENT.CUBE_STICKY
		"fixed":
			real_type = GameManager.CONTENT.CUBE_FIXED
		"boom":
			real_type = GameManager.CONTENT.CUBE_BOOM
	
	match real_type:
		GameManager.CONTENT.CUBE_NORMAL:
			$Outlook.texture = load("res://assets/pic/normal_cube.png")
		GameManager.CONTENT.CUBE_STICKY:
			$Outlook.texture = load("res://assets/pic/sticky_cube.png")
		GameManager.CONTENT.CUBE_FIXED:
			$Outlook.texture = load("res://assets/pic/fixed_cube.png")
		GameManager.CONTENT.CUBE_BOOM:
			$Outlook.texture = load("res://assets/pic/boom_cube.png")

func _process(delta):
	if is_moving:
		# 移向目标
		var direction = (target_position - position).normalized()
		var distance = position.distance_to(target_position)
		
		# 如果距离目标很近了，就重新选点
		if distance > 5:
			rotation = -(target_position - position).angle_to(Vector2.UP)
			position += direction * MOVE_SPEED * delta * speed_float
			
			#animated_outlook_shadow.set_instance_shader_parameter("shadow_angle", -global_rotation_degrees + 70)
		else:
			_pick_new_target()
	
	if is_dragging:
		position = get_global_mouse_position()

func _pick_new_target():
	var next_x: float
	if randf() < PREFER_PROBABILITY:
		if position.x < SCREEN_SIZE.x / 2:
			next_x = randf_range(0, PREFER_ZONE_WIDTH)
		else:
			next_x = randf_range(SCREEN_SIZE.x - PREFER_ZONE_WIDTH, SCREEN_SIZE.x)
	else:
		next_x = randf_range(0, SCREEN_SIZE.x)

	var next_y = randf_range(0, SCREEN_SIZE.y)

	# 限制在屏幕内（考虑 Sprite 自身大小可以加 margin）
	target_position = Vector2(
		clamp(next_x, 0, SCREEN_SIZE.x),
		clamp(next_y, 0, SCREEN_SIZE.y)
	)
	
	speed_float = randf_range(1, 2)
	animated_outlook.speed_scale = speed_float

	is_moving = true

func _on_area_2d_mouse_entered() -> void:
	if not enable:
		return
	#if _check_mouse_position():
	#	return
	animated_outlook.set_instance_shader_parameter("enable", true)
	#animated_outlook.material.set_shader_parameter("enable", true)

func _on_area_2d_mouse_exited() -> void:
	if not enable:
		return
	animated_outlook.set_instance_shader_parameter("enable", false)
	#animated_outlook.material.set_shader_parameter("enable", false)

func swirl_and_disappear():
	var tmp = get_tree().create_tween().set_parallel(true)
	
	tmp.tween_property($AnimatedOutlook, "rotation_degrees", 720, 2*GameManager.TWEEN_TIME)
	tmp.tween_property($AnimatedOutlook, "scale", Vector2(0.01, 0.01), 2*GameManager.TWEEN_TIME)
	#tmp.tween_property($AnimatedOutlookShadow, "scale", Vector2(0.01, 0.01), 2*GameManager.TWEEN_TIME)
	tmp.tween_property($AnimatedOutlook, "modulate", Color(1, 1, 1, 0), 2*GameManager.TWEEN_TIME)
	#tmp.tween_property($AnimatedOutlookShadow, "modulate", Color(1, 1, 1, 0), 2*GameManager.TWEEN_TIME)
	
	tmp.tween_property($Outlook, "modulate", Color(1, 1, 1, 1), 2*GameManager.TWEEN_TIME)
	tmp.tween_property($Outlook, "scale", Vector2(1, 1), 2*GameManager.TWEEN_TIME)
	tmp.tween_property($Outlook, "global_rotation_degrees", 0, 2*GameManager.TWEEN_TIME)
	

func swirl_and_appear():
	var tmp = get_tree().create_tween().set_parallel(true)
	
	tmp.tween_property($AnimatedOutlook, "rotation_degrees", 0, 2*GameManager.TWEEN_TIME)
	tmp.tween_property($AnimatedOutlook, "scale", Vector2(0.5, 0.5), 2*GameManager.TWEEN_TIME)
	#tmp.tween_property($AnimatedOutlookShadow, "scale", Vector2(0.5, 0.5), 2*GameManager.TWEEN_TIME)
	tmp.tween_property($AnimatedOutlook, "modulate", Color(1, 1, 1, 1), 2*GameManager.TWEEN_TIME)
	#tmp.tween_property($AnimatedOutlookShadow, "modulate", Color(1, 1, 1, 1), 2*GameManager.TWEEN_TIME)
	
	tmp.tween_property($Outlook, "modulate", Color(1, 1, 1, 0), 2*GameManager.TWEEN_TIME)
	tmp.tween_property($Outlook, "scale", Vector2(0.01, 0.01), 2*GameManager.TWEEN_TIME)
	tmp.tween_property($Outlook, "global_rotation_degrees", 720, 2*GameManager.TWEEN_TIME)


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("mouse_left"):
		#if _check_mouse_position():
		#	return
		if not enable:
			return
		
		if get_tree().get_node_count_in_group("is_dragging") > 0:
			return
		
		is_moving = false
		is_dragging = true
		swirl_and_disappear()
		
		z_index = 500
		
		add_to_group("is_dragging")
		get_tree().call_group("birds", "run_away")
		
	if event.is_action_released("mouse_left"):
		if not is_dragging:
			return
		var grid = _check_mouse_position()
		if grid:
			var obj = map_editor.create(real_type, grid, 1)
			if obj:
				remove_from_group("is_dragging")
				get_tree().call_group("birds", "queue_free")
				queue_free()
				return
		
		get_tree().call_group("birds", "come_back")
		
		is_moving = true
		is_dragging = false
		swirl_and_appear()
		_pick_new_target()
		#animated_outlook.set_instance_shader_parameter("enable", false)
		
		z_index = 0
		
		remove_from_group("is_dragging")

func _check_mouse_position():
	var mouse_position = get_global_mouse_position()
	var grid_mouse_position = mouse_position - GameManager.MIDDLE_POSITION - GameManager.map_panel_position
	
	if grid_mouse_position.x < 0 or grid_mouse_position.x >= GameManager.map_panel_size.x or\
	grid_mouse_position.y < 0 or grid_mouse_position.y >= GameManager.map_panel_size.y:
		return false
	
	@warning_ignore("integer_division")
	var grid_x = int(grid_mouse_position.x) / 64
	@warning_ignore("integer_division")
	var grid_y = int(grid_mouse_position.y) / 64
	
	return Vector2i(grid_x, grid_y)

func _on_area_2d_area_entered(area: Area2D) -> void:
	_pick_new_target()

func run_away():
	if is_dragging:
		return
	enable = false
	
	var next_x: float
	if position.x < SCREEN_SIZE.x / 2:
		next_x = position.x - SCREEN_SIZE.x
	else:
		next_x = position.x + SCREEN_SIZE.x

	var next_y: float
	if position.y < SCREEN_SIZE.y / 2:
		next_y = position.y - SCREEN_SIZE.y
	else:
		next_y = position.y + SCREEN_SIZE.y

	target_position = Vector2(next_x, next_y)
	
	speed_float = randf_range(4, 5)
	animated_outlook.speed_scale = speed_float

	is_moving = true

func come_back():
	if is_dragging:
		return
	enable = true
	
	_pick_new_target()
