extends Node2D

@onready var animated_outlook: AnimatedSprite2D = $AnimatedOutlook
@onready var animated_outlook_shadow: AnimatedSprite2D = $AnimatedOutlookShadow

# 配置参数
const SCREEN_SIZE = Vector2(1600, 900)
const PREFER_ZONE_WIDTH = 512.0
const PREFER_PROBABILITY = 0.7  # 70% 的概率倾向于去左侧区域
const MOVE_SPEED = 100.0        # 移动速度


var speed_float = 1
var target_position = Vector2.ZERO
var is_moving = false

func _ready():
	animated_outlook.play("walk")
	animated_outlook_shadow.play("walk")
	# 初始位置设为屏幕中心或左侧
	position = Vector2(PREFER_ZONE_WIDTH / 2, SCREEN_SIZE.y / 2)
	_pick_new_target()

func _process(delta):
	if is_moving:
		# 移向目标
		var direction = (target_position - position).normalized()
		var distance = position.distance_to(target_position)
		
		# 如果距离目标很近了，就重新选点
		if distance > 5:
			rotation = -(target_position - position).angle_to(Vector2.UP)
			animated_outlook_shadow.material.set_shader_parameter("shadow_angle", -global_rotation_degrees + 70)
			position += direction * MOVE_SPEED * delta * speed_float
		else:
			_pick_new_target()

func _pick_new_target():
	var next_x: float

	# 核心逻辑：权重判定
	if randf() < PREFER_PROBABILITY:
		# 倾向于在左侧 512 像素内选点
		next_x = randf_range(0, PREFER_ZONE_WIDTH)
	else:
		# 在全屏剩余范围内选点
		next_x = randf_range(0, SCREEN_SIZE.x)

	var next_y = randf_range(0, SCREEN_SIZE.y)

	# 限制在屏幕内（考虑 Sprite 自身大小可以加 margin）
	target_position = Vector2(
		clamp(next_x, 0, SCREEN_SIZE.x),
		clamp(next_y, 0, SCREEN_SIZE.y)
	)
	
	speed_float = randf_range(0.5, 1.5)

	is_moving = true


func _on_area_2d_mouse_entered() -> void:
	animated_outlook.material.set_shader_parameter("enable", true)


func _on_area_2d_mouse_exited() -> void:
	animated_outlook.material.set_shader_parameter("enable", false)
