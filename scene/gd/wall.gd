extends CubeUnit
class_name Wall

func _ready() -> void:
	$Outlook.region_rect = Rect2(64, 128 if GameManager.is_dark_mode else 0, 64, 64)
