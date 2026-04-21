extends TextureButton

var rotate_tween: Tween

func _on_mouse_entered() -> void:
	if rotate_tween:
		rotate_tween.kill()
	
	rotate_tween = get_tree().create_tween().set_parallel()
	rotate_tween.tween_property(self, "rotation_degrees", 30, GameManager.TWEEN_TIME)
	rotate_tween.tween_property(self, "scale", Vector2(1.1, 1.1), GameManager.TWEEN_TIME)


func _on_mouse_exited() -> void:
	if rotate_tween:
		rotate_tween.kill()
	
	rotate_tween = get_tree().create_tween().set_parallel()
	rotate_tween.tween_property(self, "rotation_degrees", 0, GameManager.TWEEN_TIME)
	rotate_tween.tween_property(self, "scale", Vector2(1, 1), GameManager.TWEEN_TIME)
