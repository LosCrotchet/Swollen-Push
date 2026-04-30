extends CubeUnit
class_name Wall

func _ready() -> void:
	is_fixed = true
	
	z_index = 110
	Outlook.region_rect = Rect2(64, 0, 64, 64)
	
	super._ready()
