extends CubeUnit
class_name FirePit

func _ready() -> void:
	AnimatedOutlook.visible = false
	Outlook.region_rect = Rect2(192, 128 if GameManager.is_dark_mode else 0, 64, 64)
	z_index = 11
	
	super._ready()
