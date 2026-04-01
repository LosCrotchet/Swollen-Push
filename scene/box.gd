extends Node2D

@export var coordinate: Vector2
@export var mass: int = 10
@export var type: GameManager.CONTENT = GameManager.CONTENT.BOX

var pos_tween

func move_to(to_coordinate: Vector2):
	coordinate = to_coordinate
	var to_position = (coordinate + Vector2(1, 1)) * 64
	if pos_tween:
		pos_tween.kill()
	pos_tween = get_tree().create_tween()
	pos_tween.set_ease(Tween.EASE_OUT)
	pos_tween.set_trans(Tween.TRANS_CUBIC)
	pos_tween.tween_property(self, "position", to_position, GameManager.TWEEN_TIME)
