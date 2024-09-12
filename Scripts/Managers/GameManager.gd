extends Node
class_name GameManagementClass

signal level_completed(index: int)
signal quadrant_hitted(damage_taken: float)

var game_levels: Array = []
var levels_unlocked: int = 1
var previous_levels_unlocked_index: int = 0
var current_level_index: int = 0

var builder_args: QuadrantBuilderArgs
var player: PlayerController

var pool_fracture_bullets: PoolFracture
var pool_fracture_shards: PoolFracture
var pool_cut_visualizers: PoolFracture
var pool_fracture_bodies: PoolFracture

var world_map: Node2D
const LEVELS_UNLOCKED: String = "levels_unlocked"
const SAVED_PREVIOUS_LEVELS_UNLOCKED: String = "previous_levels_unlocked_index"

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	add_to_group("PersistentNodes")
	level_completed.connect(on_level_completed)

func on_level_completed(index: int):
	if index < previous_levels_unlocked_index:
		index = previous_levels_unlocked_index
		print_debug("Index is less than the one saved: {0}. Used the saved index.".format([index]))
	else:
		previous_levels_unlocked_index = index
		print_debug("Index being passed to the level_complete signal is: ", index)
	
	levels_unlocked = index

func save_data():
	SaveSystem.set_var(LEVELS_UNLOCKED, levels_unlocked)
	SaveSystem.set_var(SAVED_PREVIOUS_LEVELS_UNLOCKED, previous_levels_unlocked_index)

func load_data():
	if !SaveSystem.has(LEVELS_UNLOCKED): return
	levels_unlocked = SaveSystem.get_var(LEVELS_UNLOCKED)
	
	if !SaveSystem.has(SAVED_PREVIOUS_LEVELS_UNLOCKED): return
	previous_levels_unlocked_index = SaveSystem.get_var(SAVED_PREVIOUS_LEVELS_UNLOCKED)
