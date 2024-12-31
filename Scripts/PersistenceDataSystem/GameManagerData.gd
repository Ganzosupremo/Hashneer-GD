class_name GameManagerData extends Resource

var levels_unlocked: int = 1
var previous_levels_unlocked_index: int = 1
var current_level: int = 0

func _init(_levels_unlocked: int = 1) -> void:
	levels_unlocked = _levels_unlocked
	previous_levels_unlocked_index = levels_unlocked
	current_level = 0
