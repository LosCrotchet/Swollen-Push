extends CubeUnit
class_name Cube

@export var statue: GameManager.STATUE = GameManager.STATUE.NORMAL	# 用来提示当前状态，仅做外观变化

var cube_scale_tween: Tween

func _ready() -> void:
	
	z_index = 20
	
	$AnimatedOutlook.sprite_frames = load("res://assets/tres/cube_frames.tres")
	$AnimatedOutlook.scale = Vector2.ONE * 0.5
	
	$Outlook.visible = false
	#$Outlook.scale = Vector2(2, 2)
	
	match type:
		GameManager.CONTENT.CUBE_SIMPLE:
			$AnimatedOutlook.visible = true
			$AnimatedOutlook.animation = "simple_1"
		GameManager.CONTENT.CUBE_STICKY:
			$Outlook.visible = true
			$AnimatedOutlook.visible = false
			$Outlook.region_rect = Rect2(64, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_STATIC:
			$AnimatedOutlook.visible = true
			$AnimatedOutlook.animation = "static_1"
		GameManager.CONTENT.CUBE_BOOM:
			$Outlook.visible = true
			$AnimatedOutlook.visible = false
			$Outlook.region_rect = Rect2(192, 192 if GameManager.is_dark_mode else 64, 64, 64)

func has_point(pos: Vector2i, set_radius: int = radius) -> bool:
	return Rect2i(coordinate-Vector2i(set_radius-1, set_radius-1), Vector2i(2*set_radius-1, 2*set_radius-1)).has_point(pos)

func set_statue(to_statue: GameManager.STATUE):
	statue = to_statue
	
	match statue:
		GameManager.STATUE.NORMAL:
			$Outlook.modulate = Color(1, 1, 1, 1)
			$AnimatedOutlook.modulate = Color(1, 1, 1, 1)
		GameManager.STATUE.INTERACTING:
			$Outlook.modulate = Color(1.0, 0.65, 0.65, 1.0)
			$AnimatedOutlook.modulate = Color(1.0, 0.65, 0.65, 1.0)
		GameManager.STATUE.PASSIVE:
			$Outlook.modulate = Color(0.65, 0.65, 1.0, 1.0)
			$AnimatedOutlook.modulate = Color(0.65, 0.65, 1.0, 1.0)

func set_radius(to_radius: int) -> bool:
	if to_radius < 1 or (to_radius > 3 and type != GameManager.CONTENT.CUBE_BOOM):
		return false

	if $Outlook.visible:
		radius = to_radius
		var to_scale = Vector2.ONE * ((radius - 1) * 2 + 1)
		
		if cube_scale_tween:
			cube_scale_tween.kill()
		cube_scale_tween = get_tree().create_tween()
		cube_scale_tween.set_ease(Tween.EASE_OUT)
		cube_scale_tween.set_trans(Tween.TRANS_CIRC)
		cube_scale_tween.tween_property($Outlook, "scale", to_scale, GameManager.TWEEN_TIME).set_delay(GameManager.TWEEN_TIME)
	
	if $AnimatedOutlook.visible:
		var animation_string_head = ""
		var origin = radius
		var dir = 1 if to_radius > radius else -1
		match type:
			GameManager.CONTENT.CUBE_SIMPLE:
				animation_string_head += "simple_"
			GameManager.CONTENT.CUBE_STICKY:
				animation_string_head += "sticky_"
			GameManager.CONTENT.CUBE_STATIC:
				animation_string_head += "static_"
			GameManager.CONTENT.CUBE_BOOM:
				animation_string_head += "boom_"
		radius = to_radius
		
		var animation_string = animation_string_head
		if dir == 1:
			animation_string += ("%d" % origin)
			$AnimatedOutlook.play(animation_string)
			#$AnimatedOutlook.animation = animation_string_head + str(to_radius)
		else:
			animation_string += ("%d" % to_radius)
			$AnimatedOutlook.play_backwards(animation_string)
			#$AnimatedOutlook.animation = animation_string_head + str(to_radius)
	
	return true
