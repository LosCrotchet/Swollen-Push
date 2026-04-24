extends CubeUnit
class_name FirePit

func _ready() -> void:
	Outlook.visible = false
	AnimatedOutlook.visible = true
	AnimatedOutlook.sprite_frames = load("res://assets/tres/cube_frames.tres")
	AnimatedOutlook.animation = "firepit"
	AnimatedOutlook.play()
	#Outlook.region_rect = Rect2(192, 128 if GameManager.is_dark_mode else 0, 64, 64)
	z_index = 10
	
	super._ready()
