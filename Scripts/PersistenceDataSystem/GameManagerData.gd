class_name GameManagerData extends Resource

@export var levels_unlocked: int = 1
@export var previous_levels_unlocked_index: int = 1
@export var current_level: int = 0

func _init(_levels_unlocked: int = 1, _previous_lvl_unlocked: int= 1, _current_lvl: int = 1) -> void:
	levels_unlocked = _levels_unlocked
	previous_levels_unlocked_index = _previous_lvl_unlocked
	current_level = _current_lvl
