extends CubeUnit
class_name Key

func _ready() -> void:
	Outlook.region_rect = Rect2(192, 0, 64, 64)
	z_index = 11
	
	super._ready()
