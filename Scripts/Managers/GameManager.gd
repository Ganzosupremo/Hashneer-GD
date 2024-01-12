extends Node
class_name GameManagementClass

signal level_completed(index: int)
signal quadrant_hitted(damage_taken: float)

var game_levels: Array = []
var levels_unlocked: int = 1
var current_level_index: int = 0
var builder_args: QuadrantBuilderArgs
var player: PlayerController
const STRING_TO_SAVE: String = "levels_unlocked"

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	add_to_group("PersistentNodes")
	level_completed.connect(on_level_completed)

func on_level_completed(index: int):
	print_debug("index being passed to the level_complete signal is: ", index)
	levels_unlocked = index

func save_data():
	SaveSystem.set_var(STRING_TO_SAVE, levels_unlocked)

func load_data():
	if SaveSystem.has(STRING_TO_SAVE):
		levels_unlocked = SaveSystem.get_var(STRING_TO_SAVE)
