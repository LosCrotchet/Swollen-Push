extends CubeUnit
class_name Hole

func _ready() -> void:
	$Outlook.region_rect = Rect2(192, 128 if GameManager.is_dark_mode else 0, 64, 64)
	z_index = 1
