class_name MiningWorldGenerator extends Node2D
## Generates a Minecraft-style 2D mining world with procedural terrain.
##
## This class handles terrain generation for the mining game mode including:
## - Noise-based terrain surface with rolling hills
## - Layered geology (dirt, stone, deep stone, bedrock)
## - Procedural cave carving using FastNoiseLite
## - Depth-based ore distribution in stone layers
## - BFS vein generation for natural ore clusters

signal generation_complete(terrain_bounds: Rect2)
signal block_generated(position: Vector2, ore_type: OreDetails.OreType)

enum TerrainLayer { AIR, DIRT, STONE, DEEP_STONE, BEDROCK }

var quadrant_size: Vector2i = Vector2i(50, 50)
var grid_size: Vector2i = Vector2i(64, 48)

var surface_amplitude: float = 8.0
var surface_base_height: float = 8.0
var dirt_layer_thickness: int = 4
var cave_threshold: float = 0.3
var cave_frequency: float = 0.08
var surface_frequency: float = 0.05
var deep_stone_start_ratio: float = 0.6

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

var _surface_noise: FastNoiseLite
var _cave_noise: FastNoiseLite
var _terrain_map: Dictionary = {}
var _surface_heights: Array[int] = []

func _ready() -> void:
        _rng = RandomNumberGenerator.new()
        _rng.randomize()
        
        _setup_noise()
        
        if not depth_config:
                depth_config = MiningDepthConfig.new()

func _setup_noise() -> void:
        _surface_noise = FastNoiseLite.new()
        _surface_noise.seed = _rng.randi()
        _surface_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
        _surface_noise.frequency = surface_frequency
        _surface_noise.fractal_octaves = 3
        _surface_noise.fractal_lacunarity = 2.0
        _surface_noise.fractal_gain = 0.5
        
        _cave_noise = FastNoiseLite.new()
        _cave_noise.seed = _rng.randi()
        _cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
        _cave_noise.frequency = cave_frequency
        _cave_noise.fractal_octaves = 4
        _cave_noise.fractal_lacunarity = 2.0
        _cave_noise.fractal_gain = 0.5

func generate_world(builder_args: WorldGenArgs) -> void:
        _initial_health = builder_args.initial_health
        quadrant_size = Vector2i(builder_args.quadrant_size, builder_args.quadrant_size)
        grid_size = builder_args.grid_size
        
        _quadrant_positions.clear()
        _terrain_map.clear()
        _surface_heights.clear()
        
        _generate_surface_heights()
        _generate_terrain_map()
        _carve_caves()
        _spawn_terrain_blocks()
        _setup_world_bounds()
        
        generation_complete.emit(_map_bounds)

func _generate_surface_heights() -> void:
        _surface_heights.resize(grid_size.x)
        for x in range(grid_size.x):
                var noise_value: float = _surface_noise.get_noise_1d(float(x))
                var surface_y: int = int(surface_base_height + noise_value * surface_amplitude)
                surface_y = clampi(surface_y, 2, grid_size.y - 2)
                _surface_heights[x] = surface_y

func _generate_terrain_map() -> void:
        var deep_stone_y: int = int(grid_size.y * deep_stone_start_ratio)
        var bedrock_y: int = grid_size.y - 1
        
        for x in range(grid_size.x):
                var surface_y: int = _surface_heights[x]
                
                for y in range(grid_size.y):
                        var cell: Vector2i = Vector2i(x, y)
                        
                        if y < surface_y:
                                _terrain_map[cell] = TerrainLayer.AIR
                        elif y == bedrock_y:
                                _terrain_map[cell] = TerrainLayer.BEDROCK
                        elif y < surface_y + dirt_layer_thickness:
                                _terrain_map[cell] = TerrainLayer.DIRT
                        elif y >= deep_stone_y:
                                _terrain_map[cell] = TerrainLayer.DEEP_STONE
                        else:
                                _terrain_map[cell] = TerrainLayer.STONE

func _carve_caves() -> void:
        for x in range(1, grid_size.x - 1):
                var surface_y: int = _surface_heights[x]
                
                for y in range(surface_y + dirt_layer_thickness, grid_size.y - 1):
                        var cell: Vector2i = Vector2i(x, y)
                        var layer: TerrainLayer = _terrain_map.get(cell, TerrainLayer.AIR)
                        
                        if layer == TerrainLayer.BEDROCK:
                                continue
                        
                        var cave_value: float = _cave_noise.get_noise_2d(float(x), float(y))
                        cave_value = (cave_value + 1.0) / 2.0
                        
                        var depth_factor: float = float(y - surface_y) / float(grid_size.y - surface_y)
                        var adjusted_threshold: float = cave_threshold - depth_factor * 0.1
                        
                        if cave_value < adjusted_threshold:
                                _terrain_map[cell] = TerrainLayer.AIR

func _spawn_terrain_blocks() -> void:
        var vein_pending: Dictionary = {}
        
        for x in range(grid_size.x):
                for y in range(grid_size.y):
                        var cell: Vector2i = Vector2i(x, y)
                        var layer: TerrainLayer = _terrain_map.get(cell, TerrainLayer.AIR)
                        
                        if layer == TerrainLayer.AIR:
                                continue
                        
                        var pos_center: Vector2 = _cell_to_world_center(cell)
                        var pos_topleft: Vector2 = _cell_to_world_topleft(cell)
                        _quadrant_positions.append(pos_topleft)
                        
                        var is_border: bool = _is_world_border(cell)
                        
                        if is_border or layer == TerrainLayer.BEDROCK:
                                _spawn_border_block(cell, pos_center, layer)
                        else:
                                _spawn_terrain_block(cell, pos_center, layer, vein_pending)

func _cell_to_world_center(cell: Vector2i) -> Vector2:
        return Vector2(
                cell.x * quadrant_size.x + quadrant_size.x / 2,
                cell.y * quadrant_size.y + quadrant_size.y / 2
        )

func _cell_to_world_topleft(cell: Vector2i) -> Vector2:
        return Vector2(cell.x * quadrant_size.x, cell.y * quadrant_size.y)

func _is_world_border(cell: Vector2i) -> bool:
        return cell.x == 0 or cell.x == grid_size.x - 1

func _spawn_border_block(cell: Vector2i, pos: Vector2, layer: TerrainLayer) -> void:
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
        block.setup(terrain_block_args, {}, true)
        
        if layer == TerrainLayer.BEDROCK:
                block.self_modulate = Color(0.2, 0.2, 0.25, 1.0)
        else:
                block.self_modulate = Color(0.3, 0.3, 0.35, 1.0)

func _spawn_terrain_block(cell: Vector2i, pos: Vector2, layer: TerrainLayer, vein_pending: Dictionary) -> void:
        if not terrain_block_template or not quadrant_nodes_parent:
                return
        
        var block: TerrainBlock = terrain_block_template.instantiate()
        quadrant_nodes_parent.add_child(block)
        
        var ore_type: OreDetails.OreType
        
        if layer == TerrainLayer.DIRT:
                ore_type = OreDetails.OreType.DIRT
        elif vein_pending.has(cell):
                ore_type = vein_pending[cell]
        elif layer == TerrainLayer.STONE or layer == TerrainLayer.DEEP_STONE:
                ore_type = _determine_ore_type(cell.y)
                if ore_type != OreDetails.OreType.DIRT:
                        _apply_vein_bfs(cell, ore_type, vein_pending)
        else:
                ore_type = OreDetails.OreType.DIRT
        
        var ore_data: OreDetails = _get_ore_resource(ore_type)
        var depth_layer: int = depth_config.calculate_depth_layer(cell.y, grid_size.y)
        var ore_health: float = _initial_health * ore_data.health_multiplier
        
        block.rectangle_size = Vector2(quadrant_size.x, quadrant_size.y)
        block.placed_in_level = true
        block.position = pos
        
        var terrain_block_args: TerrainBlock.TerrainBlockArgs = TerrainBlock.TerrainBlockArgs.new(ore_type, ore_data, depth_layer, ore_health)
        block.setup(terrain_block_args)
        
        var pos_topleft: Vector2 = Vector2(
                cell.x * quadrant_size.x,
                cell.y * quadrant_size.y
        )
        block_generated.emit(pos_topleft, ore_type)

func _layer_to_base_ore(layer: TerrainLayer) -> OreDetails.OreType:
        match layer:
                TerrainLayer.DIRT:
                        return OreDetails.OreType.DIRT
                TerrainLayer.STONE, TerrainLayer.DEEP_STONE, TerrainLayer.BEDROCK:
                        return OreDetails.OreType.DIRT
                _:
                        return OreDetails.OreType.DIRT

func _determine_ore_type(y_grid_position: int) -> OreDetails.OreType:
        var depth_layer: int = depth_config.calculate_depth_layer(y_grid_position, grid_size.y)
        var weights: Dictionary = depth_config.get_spawn_weights_for_depth(depth_layer)
        return _weighted_random_ore(weights)

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
                        if not _is_valid_stone_cell(neighbor):
                                continue
                        
                        visited[neighbor] = true
                        
                        if _rng.randf() < propagation_chance and not vein_dict.has(neighbor):
                                vein_dict[neighbor] = ore_type
                                queue.append(neighbor)
                                vein_size += 1
                                
                                if vein_size >= max_vein_size:
                                        break

func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
        return [
                Vector2i(cell.x - 1, cell.y),
                Vector2i(cell.x + 1, cell.y),
                Vector2i(cell.x, cell.y - 1),
                Vector2i(cell.x, cell.y + 1)
        ]

func _is_valid_stone_cell(cell: Vector2i) -> bool:
        if cell.x < 1 or cell.x >= grid_size.x - 1 or cell.y < 0 or cell.y >= grid_size.y:
                return false
        var layer: TerrainLayer = _terrain_map.get(cell, TerrainLayer.AIR)
        return layer == TerrainLayer.STONE or layer == TerrainLayer.DEEP_STONE

func _get_ore_resource(ore_type: OreDetails.OreType) -> OreDetails:
        if ores_dictionary.has(ore_type):
                return ores_dictionary[ore_type]
        return ores_dictionary[OreDetails.OreType.DIRT]

func _setup_world_bounds() -> void:
        if _quadrant_positions.is_empty():
                _map_bounds = Rect2(Vector2.ZERO, Vector2(grid_size.x * quadrant_size.x, grid_size.y * quadrant_size.y))
        else:
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

func get_map_bounds() -> Rect2:
        return _map_bounds

func get_quadrant_positions() -> Array[Vector2]:
        return _quadrant_positions

func get_surface_height_at(x: int) -> int:
        if x >= 0 and x < _surface_heights.size():
                return _surface_heights[x]
        return int(surface_base_height)
