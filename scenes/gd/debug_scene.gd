extends Control

func _ready() -> void:
	#OS.request_permission("android.permission.READ_EXTERNAL_STORAGE")
	#OS.request_permission("android.permission.WRITE_EXTERNAL_STORAGE")
	
	#if OS.has_feature("android"):
	#	$DebugPanel/LeftClickButton.visible = true
	#	$DebugPanel/RightClickButton.visible = true
	GameManager.is_editing = true
	
	pass


func _on_button_toggled(toggled_on: bool, type: int) -> void:
	match type:
		1: GameManager.now_setting = GameManager.CONTENT.CUBE_NORMAL
		2: GameManager.now_setting = GameManager.CONTENT.WALL
		3: GameManager.now_setting = GameManager.CONTENT.FIREBALL
		4: GameManager.now_setting = GameManager.CONTENT.FIREPIT
		5: GameManager.now_setting = GameManager.CONTENT.CUBE_STICKY
		6: GameManager.now_setting = GameManager.CONTENT.CUBE_FIXED
		7: GameManager.now_setting = GameManager.CONTENT.CUBE_BOOM

func _on_mouse_click_button_toggled(toggled_on: bool, is_left_click: bool) -> void:
	GameManager.now_mouse_click_mode = is_left_click

func _on_edit_mode_enable_toggled(toggled_on: bool) -> void:
	$DebugPanel/EditModeEnable.text = "编辑模式：" + ("开" if toggled_on else "关")
	GameManager.is_editing = toggled_on


func _on_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")
