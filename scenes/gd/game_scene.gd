extends Control

func _ready() -> void:
	GameManager.is_editing = false
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		$Panel.visible = not $Panel.visible

func _on_debug_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/debug_scene.tscn")
