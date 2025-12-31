class_name MiningDepthConfig extends Resource
## Data-driven configuration for ore spawn weights at different depth layers.
##
## This resource defines how ore distribution changes based on depth in the mining game mode.
## Each depth range can have different spawn weights for ore types.

@export_category("Depth Configuration")
@export var max_depth_layers: int = 20

@export_category("Depth Layer Weights")
@export var shallow_layer_max: int = 5
@export var shallow_weights: Dictionary = {
	OreDetails.OreType.DIRT: 0.80,
	OreDetails.OreType.COAL: 0.15,
	OreDetails.OreType.IRON: 0.05
}

@export var mid_layer_max: int = 10
@export var mid_weights: Dictionary = {
	OreDetails.OreType.DIRT: 0.60,
	OreDetails.OreType.COAL: 0.20,
	OreDetails.OreType.IRON: 0.10,
	OreDetails.OreType.COPPER: 0.05,
	OreDetails.OreType.SILVER: 0.05
}

@export var deep_layer_max: int = 15
@export var deep_weights: Dictionary = {
	OreDetails.OreType.DIRT: 0.50,
	OreDetails.OreType.COAL: 0.15,
	OreDetails.OreType.IRON: 0.15,
	OreDetails.OreType.GOLD: 0.10,
	OreDetails.OreType.EMERALD: 0.05,
	OreDetails.OreType.DIAMOND: 0.05
}

@export var bitcoin_zone_weights: Dictionary = {
	OreDetails.OreType.DIRT: 0.40,
	OreDetails.OreType.IRON: 0.20,
	OreDetails.OreType.GOLD: 0.15,
	OreDetails.OreType.DIAMOND: 0.10,
	OreDetails.OreType.SILVER: 0.14,
	OreDetails.OreType.BITCOIN_ORE: 0.01
}

@export_category("Vein Generation")
@export var vein_propagation_chance: float = 0.4
@export var vein_max_size: int = 8

## Get spawn weights for a specific depth layer.
## [param depth_layer]: The depth layer (0 to max_depth_layers).
## [return]: Dictionary of OreType to spawn weight.
func get_spawn_weights_for_depth(depth_layer: int) -> Dictionary:
	if depth_layer <= shallow_layer_max:
		return shallow_weights
	elif depth_layer <= mid_layer_max:
		return mid_weights
	elif depth_layer <= deep_layer_max:
		return deep_weights
	else:
		return bitcoin_zone_weights

## Calculate depth layer from Y grid position.
## [param y_position]: Y coordinate in grid.
## [param grid_height]: Total grid height.
## [return]: Depth layer (0 to max_depth_layers).
func calculate_depth_layer(y_position: int, grid_height: int) -> int:
	return int((float(y_position) / grid_height) * max_depth_layers)
