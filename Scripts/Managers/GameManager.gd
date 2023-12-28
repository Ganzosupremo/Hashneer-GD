extends Node
class_name GameManagementClass

signal level_completed(index: int)
signal quadrant_hitted(damage_taken: float)

var game_levels: Array = []
var levels_unlocked: int = 1
var current_level_index: int = 0
var builder_args: QuadrantBuilderArgs
var player: PlayerController

func _ready() -> void:
	level_completed.connect(on_level_completed)

func on_level_completed(index: int):
	print_debug("index being passed to the level_complete signal is: ", index)
	levels_unlocked = index
