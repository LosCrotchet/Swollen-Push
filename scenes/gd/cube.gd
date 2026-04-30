extends CubeUnit
class_name Cube

var cube_scale_tween: Tween

func _ready() -> void:
	
	z_index = 100
	
	Outlook.visible = false
	#Outlook.scale = Vector2(2, 2)
	
	match type:
		GameManager.CONTENT.CUBE_NORMAL:
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			Outlook.region_rect = Rect2(0, 64, 64, 64)
		GameManager.CONTENT.CUBE_STICKY:
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			Outlook.region_rect = Rect2(64, 64, 64, 64)
		GameManager.CONTENT.CUBE_FIXED:
			is_fixed = true
			
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			Outlook.region_rect = Rect2(128, 64, 64, 64)
		GameManager.CONTENT.CUBE_BOOM:
			Area.scale = Vector2(0.5, 0.5)
			Outlook.visible = true
			Outlook.region_rect = Rect2(192, 64, 64, 64)
	
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
	
	return true
