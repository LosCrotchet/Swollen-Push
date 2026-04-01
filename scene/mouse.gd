extends Node2D

@export var coordinate: Vector2
@export var facing: Vector2 = Vector2.RIGHT
@export var mass: int = 0
@export var type: GameManager.CONTENT = GameManager.CONTENT.MOUSE

@export var speed: float = 8
var dead_zone := 0.5

@onready var outlook: Sprite2D = $Outlook

var pos_tween

func _physics_process(delta: float) -> void:
	outlook.rotation = Vector2.RIGHT.angle_to(facing)
	
	if $MoveTimer.is_stopped():
		var dir = Vector2.ZERO
		dir = Input.get_vector("left", "right", "up", "down")
		print(dir)
		if abs(dir.x) < dead_zone:
			dir.x = 0
		if abs(dir.y) < dead_zone:
			dir.y = 0
		dir = Vector2(sign(dir.x), sign(dir.y))
		
		
		if dir != Vector2.ZERO:
			facing = dir
			if GridManager.attemp_move(self, facing):
				$MoveTimer.start(1/speed)
				move_to(coordinate + facing)

func _input(event: InputEvent) -> void:	
	if $InteractTimer.is_stopped():
		if event.is_action_pressed("interact_1"):
			var facing_coord = coordinate + facing
			$InteractTimer.start(1/speed)
			GridManager.update_cube(facing_coord, 1)
		elif event.is_action_pressed("interact_2"):
			var facing_coord = coordinate + facing
			$InteractTimer.start(1/speed)
			GridManager.update_cube(facing_coord, -1)

func move_to(to_coordinate: Vector2):
	coordinate = to_coordinate
	var to_position = (coordinate + Vector2(1, 1)) * 64
	if pos_tween:
		pos_tween.kill()
	pos_tween = get_tree().create_tween()
	pos_tween.set_ease(Tween.EASE_OUT)
	pos_tween.set_trans(Tween.TRANS_CUBIC)
	pos_tween.tween_property(self, "position", to_position, GameManager.TWEEN_TIME)
