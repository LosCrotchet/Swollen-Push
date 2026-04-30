extends Control

func _ready() -> void:
	GameManager.is_editing = false
	$GameRegion.position = GameManager.MIDDLE_POSITION
	$CanvasLayer/DebugPanel.visible = false
	
	$CanvasLayer/VersionLabel.text = "Swollen Push - v%s alpha" % ProjectSettings.get_setting("application/config/version")
	
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		$CanvasLayer/DebugPanel.visible = not $CanvasLayer/DebugPanel.visible

func _on_debug_button_pressed() -> void:
	SceneManager.change_scene("res://scenes/debug_scene.tscn", {"pattern": "scribbles"})
