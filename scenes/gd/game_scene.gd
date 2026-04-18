extends Control

func _ready() -> void:
	GameManager.is_editing = false
	pass


func _on_debug_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/debug_scene.tscn")
