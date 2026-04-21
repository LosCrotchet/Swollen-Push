extends Panel

@export var map_editor: Control
@onready var BIRD = preload("res://scenes/bird.tscn")

func create(type: String):
	var tmp = BIRD.instantiate()
	tmp.type = type
	tmp.map_editor = map_editor
	
	add_child(tmp)

func clear():
	for item in get_children():
		item.queue_free()
