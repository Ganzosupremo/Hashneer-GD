extends Resource
class_name QuadrantBuilderArgs

var quadrant_size: int
var grid_size: Vector2
var texture: Texture2D
var texture_after_collision: Texture2D
var initial_health: float
var drop_rate_multiplier: float
var level_index: int

func _init() -> void:
	quadrant_size = 0
	grid_size = Vector2.ZERO
	texture = null
	initial_health = 0.0
	drop_rate_multiplier = 0.0
	level_index = -1

func get_initial_quadrant_health() -> float:
	return initial_health
