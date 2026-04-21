extends CubeUnit
class_name Cube

var cube_scale_tween: Tween

func _ready() -> void:
	
	z_index = 100
	
	Outlook.visible = false
	#Outlook.scale = Vector2(2, 2)
	
	match type:
		GameManager.CONTENT.CUBE_NORMAL:
			#scale = Vector2(0.5, 0.5)
			#AnimatedOutlook.visible = true
			#AnimatedOutlook.animation = "simple_1"
			
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			AnimatedOutlook.visible = false
			Outlook.region_rect = Rect2(0, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_STICKY:
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			AnimatedOutlook.visible = false
			Outlook.region_rect = Rect2(64, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_FIXED:
			is_fixed = true
			#scale = Vector2(0.5, 0.5)
			#AnimatedOutlook.visible = true
			#AnimatedOutlook.animation = "static_1"
			
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			AnimatedOutlook.visible = false
			Outlook.region_rect = Rect2(128, 192 if GameManager.is_dark_mode else 64, 64, 64)
		GameManager.CONTENT.CUBE_BOOM:
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			AnimatedOutlook.visible = false
			Outlook.region_rect = Rect2(192, 192 if GameManager.is_dark_mode else 64, 64, 64)
	
	super._ready()

func has_point(pos: Vector2i, set_radius: int = radius) -> bool:
	return Rect2i(coordinate-Vector2i(set_radius-1, set_radius-1), Vector2i(2*set_radius-1, 2*set_radius-1)).has_point(pos)

func set_radius(to_radius: int) -> bool:
	if to_radius < 1 or (to_radius > 3 and type != GameManager.CONTENT.CUBE_BOOM):
		return false

	if Outlook.visible:
		radius = to_radius
		var to_scale = Vector2.ONE * ((radius - 1) * 2 + 1)
		
		if cube_scale_tween:
			cube_scale_tween.kill()
		#GridManager.enable = false
		cube_scale_tween = get_tree().create_tween().set_parallel()
		cube_scale_tween.set_ease(Tween.EASE_OUT)
		cube_scale_tween.set_trans(Tween.TRANS_BOUNCE)
		cube_scale_tween.tween_property(Outlook, "scale", to_scale, GameManager.ANIMATION_TIME)
		cube_scale_tween.tween_property(Area, "scale", to_scale*0.5, GameManager.ANIMATION_TIME)
	
	if AnimatedOutlook.visible:
		var animation_string_head = ""
		var origin = radius
		var dir = 1 if to_radius > radius else -1
		match type:
			GameManager.CONTENT.CUBE_NORMAL:
				animation_string_head += "simple_"
			GameManager.CONTENT.CUBE_STICKY:
				animation_string_head += "sticky_"
			GameManager.CONTENT.CUBE_FIXED:
				animation_string_head += "static_"
			GameManager.CONTENT.CUBE_BOOM:
				animation_string_head += "boom_"
		radius = to_radius
		
		var animation_string = animation_string_head
		if dir == 1:
			animation_string += ("%d" % origin)
			AnimatedOutlook.play(animation_string)
			#AnimatedOutlook.animation = animation_string_head + str(to_radius)
		else:
			animation_string += ("%d" % to_radius)
			AnimatedOutlook.play_backwards(animation_string)
			#AnimatedOutlook.animation = animation_string_head + str(to_radius)
	
	return true
