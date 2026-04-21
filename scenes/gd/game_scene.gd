extends Control

func _ready() -> void:
	GameManager.is_editing = false
	$GameRegion.position = GameManager.MIDDLE_POSITION
	
	$VersionLabel.text = "Swollen Push - v%s alpha" % ProjectSettings.get_setting("application/config/version")
	
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		$DebugPanel.visible = not $DebugPanel.visible

func _on_debug_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/debug_scene.tscn")
