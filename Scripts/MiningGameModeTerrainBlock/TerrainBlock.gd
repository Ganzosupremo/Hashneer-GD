class_name TerrainBlock extends FracturableStaticBody2D

var _ore_type : OreDetails.OreType
var _ore_data: OreDetails
var _depth_layer: int
var _health: float

@export var ore_pickups_dictionary: Dictionary = {
	"Bitcoin Ore": StringName("res://Scenes/Pickups/Ores/BitcoinOrePickup.tscn"),
	"Coal": StringName("res://Scenes/Pickups/Ores/CoalOrePickup.tscn"),
	"Copper": StringName("res://Scenes/Pickups/Ores/CopperOrePickup.tscn"),
	"Iron": StringName("res://Scenes/Pickups/Ores/IronOrePickup.tscn"),
	"Gold": StringName("res://Scenes/Pickups/Ores/GoldOrePickup.tscn"),
	"Diamond": StringName("res://Scenes/Pickups/Ores/DiamondOrePickup.tscn"),
	"Emerald": StringName("res://Scenes/Pickups/Ores/EmeraldOrePickup.tscn"),
	"Silver": StringName("res://Scenes/Pickups/Ores/SilverOrePickup.tscn"),
}

func setup(args: TerrainBlockArgs, texture_info: Dictionary = {}) -> void:
	_ore_type = args.ore_type
	_ore_data = args.ore_data
	_depth_layer = args.depth_layer
	_health = args.health
	self_modulate = _ore_data.ore_color
	_ore_data.set_depth_layer(_depth_layer)

	if texture_info.size() > 0: SetFractureBody(_health, texture_info)
	else: setFractureBody(_health, _ore_data.texture, _ore_data.normal_texture)

	_verify_random_drops_setup()
	_setup_drops_table()
	_add_drops_to_drops_table()

func _verify_random_drops_setup() -> void:
	if not random_drops:
		random_drops = %RandomDrops

func _setup_drops_table() -> void:
	var new_drops_table = DropsTable.new()
	new_drops_table.guaranteed_drops = 2
	new_drops_table.combined_odds = false

	random_drops.set_drops_table(new_drops_table)

# Adds appropriate drops to the drops table based on ore type
func _add_drops_to_drops_table() -> void:
	match _ore_type:
		OreDetails.OreType.DIRT:
			return  # No drops for dirt
		_:
			# Create Droppable for ore pickup
			var droppable = Droppable.new()
			var ore_name = Utils.enum_label(OreDetails.OreType, _ore_type)
			DebugLogger.info("Adding droppable for ore type: %s (enum value: %d)" % [ore_name, _ore_type])
			
			# Check if the ore name exists in the dictionary
			if not ore_pickups_dictionary.has(ore_name):
				DebugLogger.error("Ore pickup not found in dictionary for: %s. Available keys: %s" % [ore_name, str(ore_pickups_dictionary.keys())])
				return
			
			droppable.drop_path = ore_pickups_dictionary[ore_name]
			DebugLogger.info("Drop path: %s" % str(droppable.drop_path))
			
			# Validate the drop path is not empty
			if droppable.drop_path == "":
				DebugLogger.error("Drop path is empty for ore: %s" % ore_name)
				return
			random_drops.add_drop_to_drops_table(droppable)

func getOreInfo() -> Dictionary:
	return {
		"ore_type": _ore_type,
		"ore_data": _ore_data,
		"depth_layer": _depth_layer,
		"health": _health
	}

class TerrainBlockArgs extends Object:
	var ore_type: OreDetails.OreType
	var ore_data: OreDetails
	var depth_layer: int
	var health: float

	func _init(_ore_type: OreDetails.OreType, _ore_data: OreDetails, _depth_layer: int, _health: float) -> void:
		ore_type = _ore_type
		ore_data = _ore_data
		depth_layer = _depth_layer
		health = _health
