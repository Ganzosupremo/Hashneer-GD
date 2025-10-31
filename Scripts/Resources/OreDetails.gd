class_name OreDetails extends Resource
## Resource defining ore properties for mining game mode
##
## This resource holds the details for each type of ore available in the game.

enum OreType {
	DIRT,
	COAL,
	IRON,
	COPPER,
	SILVER,
	GOLD,
	DIAMOND,
	EMERALD,
	BITCOIN_ORE
}

@export_category("Ore Identity")
@export var ore_type: OreType = OreType.DIRT
@export var ore_name: String = "Unknown Ore"
@export var ore_description: String = ""

@export_category("Ore Visuals")
@export var ore_color: Color = Color.WHITE
@export var texture: Texture2D
@export var normal_texture: Texture2D
@export var pickup_texture: Texture2D
@export var particle_color: Color = Color.WHITE

@export_category("Ore Properties")
## Base fiat value when sold in shop
@export var base_value: float = 0.0
## Multiplier for value at deeper layers (value *= depth_multiplier * depth_layer)
@export var depth_multiplier: float = 1.0
## Health multiplier for blocks containing this ore
@export var health_multiplier: float = 1.0
## Spawn weight (higher = more common)
@export var spawn_weight: float = 1.0

@export_category("Audio")
@export var mining_sound: SoundEffectDetails
@export var pickup_sound: SoundEffectDetails

var _depth_layer: int = 0

func set_depth_layer(layer: int) -> void:
	_depth_layer = layer

func get_depth_layer() -> int:
	return _depth_layer

## Calculate final value based on depth
func get_value_at_depth(depth: int) -> float:
	return base_value * (1.0 + (depth * depth_multiplier))
