extends Panel

@export var map_editor: Control
@onready var BIRD = preload("res://scenes/bird.tscn")

signal drag_

func create(type: String):
	var tmp = BIRD.instantiate()
	tmp.type = type
	tmp.map_editor = map_editor
	
	tmp.add_to_group("birds")
	add_child(tmp)

func clear():
	for item in get_children():
		item.queue_free()
