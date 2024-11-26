extends Node2D

#signal level_completed(index: int)
signal quadrant_hitted(damage_taken: float)

@export_category("Player Resources")
## Used to easily modify/upgrade the values needed for the player like speed, health, etc.
@export var player_details: PlayerDetails

@export_category("Weapon Resources")
## Just in case something needs to access the different weapon details
@export var weapon_details_dictionary: Dictionary

var game_levels: Array = []
var levels_unlocked: int = 1
var previous_levels_unlocked_index: int = 0
var current_level: int = 0

var builder_args: QuadrantBuilderArgs
var player: PlayerController
var pool_fracture_bullets: PoolFracture


const LEVELS_UNLOCKED: String = "levels_unlocked"
const SAVED_PREVIOUS_LEVELS_UNLOCKED: String = "previous_levels_unlocked_index"
const PLAYER_DETAILS_SAVE_KEY: String = "player_details"


const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	add_to_group("PersistentNodes")


func level_completed() -> void:
	if current_level < previous_levels_unlocked_index:
		return
	
	previous_levels_unlocked_index = levels_unlocked
	levels_unlocked += 1

func add_weapon_details_to_dictionary(key: String, value: WeaponDetails) -> void:
	weapon_details_dictionary[key] = value
	print_rich(weapon_details_dictionary)
	
	

func get_weapon_details_from_dictionary(key: String) -> WeaponDetails:
	if weapon_details_dictionary.has(key):
		return weapon_details_dictionary[key]
	else:
		printerr("NO STAT VALUE FOUND FOR {0} ON {1}".format([key, self.name]))
		return null


func save_data() -> void:
	SaveSystem.set_var(LEVELS_UNLOCKED, levels_unlocked)
	SaveSystem.set_var(SAVED_PREVIOUS_LEVELS_UNLOCKED, previous_levels_unlocked_index)
	SaveSystem.set_var(PLAYER_DETAILS_SAVE_KEY, player_details)

func load_data() -> void:
	if !SaveSystem.has(LEVELS_UNLOCKED): return
	if !SaveSystem.has(SAVED_PREVIOUS_LEVELS_UNLOCKED): return
	
	levels_unlocked = SaveSystem.get_var(LEVELS_UNLOCKED)
	previous_levels_unlocked_index = SaveSystem.get_var(SAVED_PREVIOUS_LEVELS_UNLOCKED)
	
	#if SaveSystem.has(PLAYER_DETAILS_SAVE_KEY):
		#player_details = build_resource(SaveSystem.get_var(PLAYER_DETAILS_SAVE_KEY), PlayerDetails.new())


func build_resource(data: Dictionary, resource_type: Resource) ->  Resource:
	var res:= resource_type
	for i in range(data.size()):
		var key = data.keys()[i]
		var value = data.values()[i]
		res.set(key, value)
	return res
