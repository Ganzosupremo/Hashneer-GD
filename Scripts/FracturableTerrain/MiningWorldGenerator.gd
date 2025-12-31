class_name MiningWorldGenerator extends Node2D
## Generates the mining world terrain with ore distribution and borders.
##
## This class handles all terrain generation for the mining game mode including:
## - Grid-based terrain block placement
## - Depth-based ore distribution using MiningDepthConfig
## - Vein generation using BFS algorithm for natural ore clusters
## - Border block creation for world boundaries

signal generation_complete(terrain_bounds: Rect2)
signal block_generated(position: Vector2, ore_type: OreDetails.OreType)

var quadrant_size: Vector2i = Vector2i(50, 50)
var grid_size: Vector2i = Vector2i(16, 16)

var depth_config: MiningDepthConfig
var ores_dictionary: Dictionary = {
	OreDetails.OreType.DIRT: preload("res://Resources/Ores/Dirt.tres"),
	OreDetails.OreType.COAL: preload("res://Resources/Ores/Coal.tres"),
	OreDetails.OreType.IRON: preload("res://Resources/Ores/Iron.tres"),
	OreDetails.OreType.COPPER: preload("res://Resources/Ores/Copper.tres"),
	OreDetails.OreType.SILVER: preload("res://Resources/Ores/Silver.tres"),
	OreDetails.OreType.GOLD: preload("res://Resources/Ores/Gold.tres"),
	OreDetails.OreType.DIAMOND: preload("res://Resources/Ores/Diamond.tres"),
	OreDetails.OreType.EMERALD: preload("res://Resources/Ores/Emerald.tres"),
	OreDetails.OreType.BITCOIN_ORE: preload("res://Resources/Ores/Bitcoin.tres")
}

var terrain_block_template: PackedScene

var quadrant_nodes_parent: Node2D
var shop_layer: ShopLayer
var world_borders: WorldBorders
var digital_ambiance: DigitalAmbiance
var shop_layer_height: float = 500.0

var _rng: RandomNumberGenerator
var _quadrant_positions: Array[Vector2] = []
var _map_bounds: Rect2
var _initial_health: float = 100.0

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
		
	if not depth_config:
		depth_config = MiningDepthConfig.new()

## Initialize and generate the mining world.
## [param builder_args]: Level configuration arguments.
func generate_world(builder_args: WorldGenArgs) -> void:
	_initial_health = builder_args.initial_health
	quadrant_size = Vector2i(builder_args.quadrant_size, builder_args.quadrant_size)
	grid_size = builder_args.grid_size
		
	_quadrant_positions.clear()
	_generate_terrain_grid()
	_setup_world_bounds()
		
	generation_complete.emit(_map_bounds)

## Generate the terrain grid with ore distribution.
func _generate_terrain_grid() -> void:
	var vein_pending: Dictionary = {}
	var valid_cells: Array[Vector2i] = MapGeometry.get_valid_cells(grid_size, quadrant_size, Constants.MapShape.Square)
		
	for cell in valid_cells:
		var is_border: bool = MapGeometry.is_border_cell(cell, grid_size)
		var pos: Vector2 = MapGeometry.cell_to_world(cell, quadrant_size)
		_quadrant_positions.append(pos)
				
		if is_border:
			_spawn_border_block(cell, pos)
		else:
			_spawn_terrain_block(cell, pos, vein_pending)

## Spawn an indestructible border block.
func _spawn_border_block(cell: Vector2i, pos: Vector2) -> void:
	if not terrain_block_template or not quadrant_nodes_parent:
		return
		
	var block: TerrainBlock = terrain_block_template.instantiate()
	quadrant_nodes_parent.add_child(block)
	block.fracturable = false
	block.rectangle_size = Vector2(quadrant_size.x, quadrant_size.y)
	block.placed_in_level = true
	block.position = pos
		
	var ore_type: OreDetails.OreType = OreDetails.OreType.DIRT
	var ore_data: OreDetails = _get_ore_resource(ore_type)
	var depth_layer: int = depth_config.calculate_depth_layer(cell.y, grid_size.y)
	var ore_health: float = INF
		
	var terrain_block_args: TerrainBlock.TerrainBlockArgs = TerrainBlock.TerrainBlockArgs.new(ore_type, ore_data, depth_layer, ore_health)
	block.setup(terrain_block_args)

## Spawn a regular destructible terrain block with ore.
func _spawn_terrain_block(cell: Vector2i, pos: Vector2, vein_pending: Dictionary) -> void:
	if not terrain_block_template or not quadrant_nodes_parent:
		return
		
	var block: TerrainBlock = terrain_block_template.instantiate()
	quadrant_nodes_parent.add_child(block)
		
	var ore_type: OreDetails.OreType
	if vein_pending.has(cell):
		ore_type = vein_pending[cell]
	else:
		ore_type = _determine_ore_type(cell.y)
		if ore_type != OreDetails.OreType.DIRT:
			_apply_vein_bfs(cell, ore_type, vein_pending)
		
	var ore_data: OreDetails = _get_ore_resource(ore_type)
	var depth_layer: int = depth_config.calculate_depth_layer(cell.y, grid_size.y)
	var ore_health: float = _initial_health * ore_data.health_multiplier
		
	block.rectangle_size = Vector2(quadrant_size.x, quadrant_size.y)
	block.placed_in_level = true
	block.position = pos
		
	var terrain_block_args: TerrainBlock.TerrainBlockArgs = TerrainBlock.TerrainBlockArgs.new(ore_type, ore_data, depth_layer, ore_health)
	block.setup(terrain_block_args)
		
	block_generated.emit(pos, ore_type)

## Determine ore type based on depth using weighted random selection.
func _determine_ore_type(y_grid_position: int) -> OreDetails.OreType:
	var depth_layer: int = depth_config.calculate_depth_layer(y_grid_position, grid_size.y)
	var weights: Dictionary = depth_config.get_spawn_weights_for_depth(depth_layer)
	return _weighted_random_ore(weights)

## Weighted random ore selection.
func _weighted_random_ore(weights: Dictionary) -> OreDetails.OreType:
	var total_weight: float = 0.0
	for weight in weights.values():
		total_weight += weight
		
	var rand_value: float = _rng.randf() * total_weight
	var cumulative_weight: float = 0.0
		
	for ore_type in weights.keys():
		cumulative_weight += weights[ore_type]
		if rand_value <= cumulative_weight:
			return ore_type
		
	return OreDetails.OreType.DIRT

## Apply vein generation using BFS for more natural ore clusters.
## [param start_cell]: The starting cell for the vein.
## [param ore_type]: The ore type to propagate.
## [param vein_dict]: Dictionary to store pending vein cells.
func _apply_vein_bfs(start_cell: Vector2i, ore_type: OreDetails.OreType, vein_dict: Dictionary) -> void:
	var queue: Array[Vector2i] = []
	var visited: Dictionary = {}
	var vein_size: int = 0
	var max_vein_size: int = depth_config.vein_max_size
	var propagation_chance: float = depth_config.vein_propagation_chance
		
	queue.append(start_cell)
	visited[start_cell] = true
		
	while queue.size() > 0 and vein_size < max_vein_size:
		var current: Vector2i = queue.pop_front()
				
		var neighbors: Array[Vector2i] = _get_neighbors(current)
		for neighbor in neighbors:
			if visited.has(neighbor):
				continue
			if not _is_valid_cell(neighbor):
				continue
			if MapGeometry.is_border_cell(neighbor, grid_size):
				continue
						
			visited[neighbor] = true
						
			if _rng.randf() < propagation_chance and not vein_dict.has(neighbor):
				vein_dict[neighbor] = ore_type
				queue.append(neighbor)
				vein_size += 1
								
				if vein_size >= max_vein_size:
					break

## Get neighboring cells (4-directional).
func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(cell.x - 1, cell.y),
		Vector2i(cell.x + 1, cell.y),
		Vector2i(cell.x, cell.y - 1),
		Vector2i(cell.x, cell.y + 1)
	]

## Check if a cell is within grid bounds.
func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < grid_size.x and cell.y >= 0 and cell.y < grid_size.y

## Get ore resource from dictionary.
func _get_ore_resource(ore_type: OreDetails.OreType) -> OreDetails:
	if ores_dictionary.has(ore_type):
		return ores_dictionary[ore_type]
	return ores_dictionary[OreDetails.OreType.DIRT]

## Setup world bounds, shop layer, and borders.
func _setup_world_bounds() -> void:
	_map_bounds = MapGeometry.calculate_bounds_from_positions(_quadrant_positions, quadrant_size, false)
		
	var terrain_width: float = _map_bounds.size.x
	var terrain_height: float = _map_bounds.size.y
		
	if shop_layer:
		shop_layer.initialize(terrain_width)
		
	if world_borders:
		world_borders.generate_shop_layer_borders(terrain_width, terrain_height, shop_layer_height)
		
	if digital_ambiance:
		var full_bounds: Rect2 = Rect2(
			_map_bounds.position,
			Vector2(terrain_width, terrain_height + shop_layer_height)
		)
		digital_ambiance.set_world_bounds(full_bounds)
		digital_ambiance.add_data_particles()

## Get the calculated map bounds.
func get_map_bounds() -> Rect2:
	return _map_bounds

## Get all quadrant positions.
func get_quadrant_positions() -> Array[Vector2]:
	return _quadrant_positions
