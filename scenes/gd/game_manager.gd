extends Node

var is_editing: bool = true
var now_setting: CONTENT = CONTENT.CUBE_NORMAL
var is_dark_mode: bool = true
var now_mouse_click_mode: bool = true

var now_level: int = 0

var ANIMATION_TIME := 0.6
const TWEEN_TIME := 0.1
const HEIGHT: int = 12
const WIDTH: int = 16

const RIGHT_POSITION = Vector2(512, 0)
const MIDDLE_POSITION = Vector2(288, 0)

var map_panel_size := Vector2.ZERO
var map_panel_position := Vector2.ZERO

# 方块的类型
enum CONTENT{
	CUBE_NORMAL,
	CUBE_STICKY,
	CUBE_FIXED,
	CUBE_BOOM,
	FIREBALL,
	FIREPIT,
	WALL
}
