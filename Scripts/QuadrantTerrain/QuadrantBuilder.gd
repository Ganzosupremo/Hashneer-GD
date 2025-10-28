class_name QuadrantBuilder extends Node2D
## This script is responsible for building the terrain of the game world.
## 
## It initializes the terrain with a grid of blocks, handles gravity effects, and manages the fracturing of blocks when damaged.
## It also manages the _player's position and the block core, which is the main objective of the game.
## It uses the [BlockCore] for the core block, [QuadrantTerrain] for the terrain, and [GameManager] for game state management.


#region Exports

@export_category("Settings")
@export_group("General")
## The music to play in the background.
@export var music: MusicDetails

@export_group("Size and Color")
## The size of each quadrant in the grid.
@export var quadrant_size: Vector2i = Vector2i(50, 50)
## The size of the grid in terms of quadrants.
@export var grid_size: Vector2i = Vector2i(16, 16)
## The color of the fracture bodies.
@export var fracture_body_color: Color


@export_group("Gravity Settings")
## Whether to enable center gravity.
@export var enable_center_gravity: bool = true
## The strength of the gravity applied to the _player.
@export var gravity_strength: float = 600.0
## The exponent for the gravity falloff.
@export var gravity_falloff: float = 2.0


## New ore-based properties
@export_category("Mining Mode")
@export var mining_mode_enabled: bool = false
@export var current_depth_layer: int = 0  # 0-20
@export var ore_spawn_weights: Dictionary = {}  # Populated from LevelBuilderArgs


#endregion

@onready var _player: PlayerController = %Player
@onready var _quadrant_nodes: Node2D = %Quadrants
@onready var _static_body_template: PackedScene = preload("res://Scenes/QuadrantTerrain/StaticBody2DTemplate.tscn")

@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _rigid_bodies_parent: Node2D = %RigidBodiesParent
@onready var _pool_cut_visualizer: PoolFracture = $"../PoolFractureCutVisualizer"
@onready var _pool_fracture_shards: PoolFracture = $"../PoolFractureShards"
@onready var pool_fracture_bodies: PoolFracture = $"../Pool_FractureBodies"
@onready var block_core: BlockCore = %BlockCore
@onready var map_boundaries: StaticBody2D = %MapBoundaries
@onready var center: Area2D = %Center

var _polygon_fracture: PolygonFracture
var _fracture_disabled: bool = false
var _cur_fracture_color: Color = fracture_body_color
var builder_args: LevelBuilderArgs
var _map_bounds: Rect2
var _grid_center: Vector2
var _map_shape: Constants.MapShape = Constants.MapShape.Square
var _quadrant_positions: Array = []


#region Public API

func _ready() -> void:
	GameManager._current_quadrant_builder = self
	AudioManager.change_music_clip(music)
	_init_builder()

func _physics_process(_delta: float) -> void:
	if not enable_center_gravity: return

	if _player and is_instance_valid(_player):
		var gravity_force = _calculate_gravity_force(_player.global_position)
		_player.apply_gravity(gravity_force)

## Handles the fracturing of the source polygon (Quadrant) at the given position.[br]
## [param source] The source polygon to be fractured.[br]
## [param cut_pos] The position where the cut occurred.[br]
## [param cut_shape] The shape of the cut.[br]
## [param cut_rot] The rotation of the cut.[br]
## [param fade_speed] The speed at which the visualizer fades.
func fracture_quadrant_on_collision(pos : Vector2, other_body: FracturableStaticBody2D, bullet_launch_velocity:float = 410.0, bullet_damage: float = 25.0, bullet_speed: float = 500.0) -> void:
	var p = bullet_launch_velocity / bullet_speed
	var cut_shape: PackedVector2Array = _polygon_fracture.generateRandomPolygon(Vector2(100,50) * p, Vector2(8,32), Vector2.ZERO)
	_spawn_cut_visualizers(pos, cut_shape, 10.0)
	
	if !other_body.take_damage(bullet_damage):
		return
	
	if _fracture_disabled: return
	_fracture_disabled = true
	_cut_polygons(other_body, pos, cut_shape, 45.0, 10.0)
	other_body.random_drops.spawn_drops(1)
	
	set_deferred("_fracture_disabled", false)

## Fractures the block core at the given position with the specified parameters.[br]
## [param bullet_damage]: The damage to deal to the block core.[br]
## [param miner]: The miner that will mine the block.[br]
## [param instakill]: Whether the block core should be instakilled.[br]
func fracture_block_core(bullet_damage: float, miner: String = "Player", instakill: bool = false) -> void:
	if _fracture_disabled: return
	_fracture_disabled = true
	
	block_core.fracture(builder_args.block_core_cuts_delaunay, builder_args.block_core_cut_min_area, bullet_damage, _cur_fracture_color, instakill, miner)
	
	set_deferred("_fracture_disabled", false)

#endregion

#region Private Functions

func _calculate_gravity_force(target_position: Vector2) -> Vector2:
	var direction = (_grid_center - target_position).normalized()
	var distance = target_position.distance_to(_grid_center)
	if distance < 0.001:
		return Vector2.ZERO
	var force_magnitude = gravity_strength / pow(distance, gravity_falloff)  # Simplified falloff

	return direction * force_magnitude

func _calculate_map_bounds() -> void:
	if _quadrant_positions.is_empty():
		_map_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
		return

	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	for pos in _quadrant_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x + quadrant_size.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y + quadrant_size.y)

	var level_width: float = max_x - min_x
	var level_height: float = max_y - min_y
	var buffer: float = max(level_width, level_height) * 0.5
	_map_bounds = Rect2(
		Vector2(min_x - buffer, min_y - buffer),
		Vector2(level_width + buffer * 2, level_height + buffer * 2)
	)

	_create_boundary_walls()

func _create_boundary_walls() -> void:
	# Wall thickness
	var thickness: float = 75.0
	var horizontal_offset: float = 1.2

	# Calculate map center
	var vcenter: Vector2 = Vector2(
		_map_bounds.position.x + _map_bounds.size.x/2,
		_map_bounds.position.y + _map_bounds.size.y/2
	)

	## Calculate adjusted width for top/bottom walls
	var horizontal_wall_width: float = _map_bounds.size.x * horizontal_offset + thickness * 2
	
	var wall_configs: Array = [
		# Top wall (adjusted width)
		{
			"size": Vector2(horizontal_wall_width, thickness),
			"position": vcenter + Vector2(0, -_map_bounds.size.y/2 - thickness/2)
		},
		# Right wall
		{
			"size": Vector2(thickness, _map_bounds.size.y + thickness * 2),
			"position": vcenter + Vector2(_map_bounds.size.x/2 + thickness/2, 0) * horizontal_offset
		},
		# Bottom wall (adjusted width)
		{
			"size": Vector2(horizontal_wall_width, thickness),
			"position": vcenter + Vector2(0, _map_bounds.size.y/2 + thickness/2)
		},
		# Left wall
		{
			"size": Vector2(thickness, _map_bounds.size.y + thickness * 2),
			"position": vcenter + Vector2(-_map_bounds.size.x/2 - thickness/2, 0) * horizontal_offset
		}
	]

	for config in wall_configs:
		var wall: StaticBody2D = StaticBody2D.new()
		var collision_shape: CollisionShape2D = CollisionShape2D.new()
		var rect_shape: RectangleShape2D = RectangleShape2D.new()

		rect_shape.size = config.size
		collision_shape.shape = rect_shape
		wall.position = config.position

		wall.add_child(collision_shape)
		map_boundaries.add_child(wall)


## Initializes the builder with the arguments from the current level.
func _init_builder() -> void:
	var builder_data: LevelBuilderArgs = GameManager._current_level_args
	builder_args = builder_data

	quadrant_size = Vector2i(builder_data.quadrant_size, builder_data.quadrant_size)
	grid_size = builder_data.grid_size
	_map_shape = builder_data.map_shape
	
	_polygon_fracture = PolygonFracture.new()
	_rng.randomize()
	
	var color := Color.WHITE
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	_quadrant_nodes.modulate = _cur_fracture_color
	_rigid_bodies_parent.modulate = _cur_fracture_color

	_calculate_grid_center()
	_initialize_grid_of_blocks(builder_args.initial_health)
	_set_player_position()

func _calculate_grid_center() -> void:
	_grid_center = Vector2(
		grid_size.x * quadrant_size.x / 2.0,
		grid_size.y * quadrant_size.y / 2.0
	)
	center.global_position = _grid_center

func _is_cell_in_shape(cell: Vector2i) -> bool:
	var cell_center = (Vector2(cell) + Vector2(0.5, 0.5)) * Vector2(quadrant_size)
	match _map_shape:
		Constants.MapShape.Circle:
			var radius = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			return cell_center.distance_to(_grid_center) <= radius
		Constants.MapShape.Diamond:
			var rx = grid_size.x * quadrant_size.x / 2.0
			var ry = grid_size.y * quadrant_size.y / 2.0
			return abs(cell_center.x - _grid_center.x) / rx + abs(cell_center.y - _grid_center.y) / ry <= 1.0
		Constants.MapShape.Cross:
			var mid_x = grid_size.x / 2.0
			var mid_y = grid_size.y / 2.0
			var thickness = max(1, int(min(grid_size.x, grid_size.y) * 0.25))
			return abs(cell.x + 0.5 - mid_x) <= thickness or abs(cell.y + 0.5 - mid_y) <= thickness
		Constants.MapShape.Ring:
			var radius_outer = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			var radius_inner = radius_outer * 0.5
			var distance = cell_center.distance_to(_grid_center)
			return distance <= radius_outer and distance >= radius_inner
		Constants.MapShape.LShape:
			var thickness = max(1, int(min(grid_size.x, grid_size.y) * 0.3))
			return cell.x < thickness or cell.y >= grid_size.y - thickness
		_:
			return true

#region Ore Integration

## Modified initialization
func _initialize_grid_of_blocks(initial_health: float) -> void:
	_quadrant_positions.clear()
	for i in range(grid_size.x):
		for j in range(grid_size.y):
			var cell: Vector2i = Vector2i(i, j)
			if not _is_cell_in_shape(cell):
				continue
			
			var block: FracturableStaticBody2D = _static_body_template.instantiate()
			_quadrant_nodes.add_child(block)
			
			# NEW: Determine ore type based on depth
			var ore_type: OreDetails.OreType = _determine_ore_type(j)
			var ore_data: OreDetails = _get_ore_resource(ore_type)
			
			# Set block properties based on ore type
			block.rectangle_size = Vector2(builder_args.quadrant_size, builder_args.quadrant_size)
			block.placed_in_level = true
			var pos = Vector2(i * quadrant_size.x, j * quadrant_size.y)
			block.position = pos
			_quadrant_positions.append(pos)
			
			# NEW: Use ore-specific health and texture
			var ore_health = initial_health * ore_data.health_multiplier
			block.setFractureBody(ore_health, ore_data.texture, builder_args.normal_texture)
			block.self_modulate = ore_data.ore_color
			
			# Store ore metadata for drop spawning
			block.set_meta("ore_type", ore_type)
			block.set_meta("ore_data", ore_data)

func _determine_ore_type(y_grid_position: int) -> OreDetails.OreType:
	# Calculate depth layer (0-20) based on Y position
	var depth_layer = int((float(y_grid_position) / grid_size.y) * 20.0)
	
	# Get spawn weights for this depth
	var weights = _get_spawn_weights_for_depth(depth_layer)
	
	# Weighted random selection
	return _weighted_random_ore(weights)


func _get_spawn_weights_for_depth(depth_layer: int) -> Dictionary:
	if depth_layer <= 5:
		return {
			OreDetails.OreType.DIRT: 0.80,
			OreDetails.OreType.COAL: 0.15,
			OreDetails.OreType.IRON: 0.05
		}
	elif depth_layer <= 10:
		return {
			OreDetails.OreType.DIRT: 0.60,
			OreDetails.OreType.COAL: 0.20,
			OreDetails.OreType.IRON: 0.10,
			OreDetails.OreType.COPPER: 0.05,
			OreDetails.OreType.SILVER: 0.05
		}
	elif depth_layer <= 15:
		return {
			OreDetails.OreType.DIRT: 0.50,
			OreDetails.OreType.COAL: 0.15,
			OreDetails.OreType.IRON: 0.15,
			OreDetails.OreType.GOLD: 0.10,
			OreDetails.OreType.EMERALD: 0.05,
			OreDetails.OreType.DIAMOND: 0.05
		}
	else: # 16-20 Bitcoin zone
		return {
			OreDetails.OreType.DIRT: 0.40,
			OreDetails.OreType.IRON: 0.20,
			OreDetails.OreType.GOLD: 0.15,
			OreDetails.OreType.DIAMOND: 0.10,
			OreDetails.OreType.SILVER: 0.14,
			OreDetails.OreType.BITCOIN_ORE: 0.01
		}


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
	
	# Fallback
	return OreDetails.OreType.DIRT


func _get_ore_resource(ore_type: OreDetails.OreType) -> OreDetails:
	match ore_type:
		OreDetails.OreType.DIRT:
			return preload("res://Resources/Ores/DirtOre.tres")
		OreDetails.OreType.COAL:
			return preload("res://Resources/Ores/CoalOre.tres")
		OreDetails.OreType.IRON:
			return preload("res://Resources/Ores/IronOre.tres")
		OreDetails.OreType.COPPER:
			return preload("res://Resources/Ores/CopperOre.tres")
		OreDetails.OreType.SILVER:
			return preload("res://Resources/Ores/SilverOre.tres")
		OreDetails.OreType.GOLD:
			return preload("res://Resources/Ores/GoldOre.tres")
		OreDetails.OreType.DIAMOND:
			return preload("res://Resources/Ores/DiamondOre.tres")
		OreDetails.OreType.EMERALD:
			return preload("res://Resources/Ores/EmeraldOre.tres")
		OreDetails.OreType.BITCOIN_ORE:
			return preload("res://Resources/Ores/BitcoinOre.tres")
		_:
			return preload("res://Resources/Ores/DirtOre.tres")

#endregion

func _set_player_position() -> void:
	## Set the _player position to a random position within the grid of blocks with a little offset
	## This is to avoid the _player to be spawned in the same position as the block core or inside a block
	var offset: Vector2 = Vector2(20, 20)
	var spawn_point: Vector2 = Vector2.ZERO

		# Choose random edge to spawn
	match _rng.randi_range(0, 3):
		0: # Top
			spawn_point = Vector2(
				_rng.randf_range(_map_bounds.position.x, _map_bounds.end.x),
				_map_bounds.position.y + offset.y
			)
		1: # Right
			spawn_point = Vector2(
				_map_bounds.end.x - offset.x,
				_rng.randf_range(_map_bounds.position.y, _map_bounds.end.y)
			)
		2: # Bottom
			spawn_point = Vector2(
				_rng.randf_range(_map_bounds.position.x, _map_bounds.end.x),
				_map_bounds.end.y - offset.y
			)
		3: # Left
			spawn_point = Vector2(
				_map_bounds.position.x + offset.x,
				_rng.randf_range(_map_bounds.position.y, _map_bounds.end.y)
			)
	_player.global_position = spawn_point

func _initialize_block_core():
	var bounds: Rect2 = block_core.get_bounding_square()
	var core_size: float = bounds.size.x

	var padding: float = core_size * 0.5
	block_core.global_position = _random_position_within_shape(padding)
	block_core.health.set_max_health(builder_args.initial_health * 2.0) # May change to scale exponentially

func _point_inside_shape(point: Vector2) -> bool:
	match _map_shape:
		Constants.MapShape.Circle:
			var radius = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			return point.distance_to(_grid_center) <= radius
		Constants.MapShape.Diamond:
			var rx = grid_size.x * quadrant_size.x / 2.0
			var ry = grid_size.y * quadrant_size.y / 2.0
			return abs(point.x - _grid_center.x) / rx + abs(point.y - _grid_center.y) / ry <= 1.0
		Constants.MapShape.Cross:
			var mid_x = grid_size.x * quadrant_size.x / 2.0
			var mid_y = grid_size.y * quadrant_size.y / 2.0
			var thickness = max(quadrant_size.x, quadrant_size.y) * min(grid_size.x, grid_size.y) * 0.1
			return abs(point.x - mid_x) <= thickness or abs(point.y - mid_y) <= thickness
		Constants.MapShape.Ring:
			var radius_outer = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
			var radius_inner = radius_outer * 0.5
			var d = point.distance_to(_grid_center)
			return d <= radius_outer and d >= radius_inner
		Constants.MapShape.LShape:
			var thickness = max(quadrant_size.x, quadrant_size.y) * min(grid_size.x, grid_size.y) * 0.3
			return point.x <= thickness or point.y >= grid_size.y * quadrant_size.y - thickness
		_:
			return Rect2(Vector2.ZERO, quadrant_size * grid_size).has_point(point)

func _random_position_within_shape(padding: float) -> Vector2:
	var min_pos: Vector2 = Vector2(padding, padding)
	var max_pos: Vector2 = Vector2(quadrant_size) * Vector2(grid_size) - Vector2(padding, padding)
	var attempts: int = 0
	while attempts < 50:
		var random_x: float = _rng.randf_range(min_pos.x, max_pos.x)
		var random_y: float = _rng.randf_range(min_pos.y, max_pos.y)
		var p = Vector2(random_x, random_y)
		if _point_inside_shape(p):
			return p
		attempts += 1
	return _grid_center

func _cut_polygons(source: Node2D, cut_pos: Vector2, cut_shape : PackedVector2Array, cut_rot : float, fade_speed : float = 2.0) -> void:
	_spawn_cut_visualizers(cut_pos, cut_shape, fade_speed)
	var source_polygon: PackedVector2Array = source.get_polygon()
	var total_area: float = PolygonLib.getPolygonArea(source_polygon)
	
	var source_transform: Transform2D = source.get_global_transform()
	var cut_transform := Transform2D(cut_rot, cut_pos)
	
	var s_mass : float = 1.0
	
	var cut_fracture_info: Dictionary = _polygon_fracture.cutFracture(source_polygon, cut_shape, source_transform, cut_transform, 1000.0, 500.0, 100.0, 21)
	
	if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
		print('empty dictionary')
		return
	
	for fracture in cut_fracture_info.fractures:
		for fracture_shard in fracture:
			var area_p: float = fracture_shard.area / total_area
			var rand_lifetime : float = _rng.randf_range(1.5, 2.5) + 2.0 * area_p
			_spawn_fracture_shards(fracture_shard, source.getTextureInfo(), s_mass * area_p, rand_lifetime)
	
	for shape in cut_fracture_info.shapes:
		call_deferred("_spawn_staticbody", shape, source.modulate, source.getTextureInfo())
	
	source.queue_free()

# Spawns little polygons shards (for visual effects) at the position where the collision happened.
# The shards will have a random lifetime and mass based on the area of the original polygon that was fractured.
# The shards will shrink and disappear after the lifetime is over.
# @param texture_info The dictionary containing the texture information.
# @param new_mass The new mass of the shard.
# @param life_time The lifetime of the shard.
func _spawn_fracture_shards(fracture_shard : Dictionary, texture_info : Dictionary, new_mass : float, life_time : float) -> void:
	var instance_fbody = _pool_fracture_shards.getInstance()
	if not instance_fbody:
		return
	
	instance_fbody.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), life_time)
	instance_fbody.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
	instance_fbody.setMass(new_mass)

# Spawns a little polygon cut that serves as feedback to the _player on where the collision happened.
# @param pos The position where the cut occurred.
# @param poly The shape of the cut.
# @param fade_speed The speed at which the visualizer fades.
func _spawn_cut_visualizers(pos : Vector2, poly : PackedVector2Array, fade_speed : float) -> void:
	var instance_visualizers = _pool_cut_visualizer.getInstance()
	instance_visualizers.spawn(pos, fade_speed)
	instance_visualizers.setPolygon(poly)

# Spawn a static body at the collision position with the ramaining shape of the original polygon
func _spawn_staticbody(shape_info : Dictionary, color : Color, texture_info : Dictionary) -> void:
	var instance_staticbody: FracturableStaticBody2D = _static_body_template.instantiate()
	_rigid_bodies_parent.add_child(instance_staticbody)
	instance_staticbody.global_position = shape_info.spawn_pos
	instance_staticbody.global_rotation = shape_info.spawn_rot
	instance_staticbody.set_polygon(shape_info.centered_shape)
	instance_staticbody.self_modulate = color
	instance_staticbody.set_fracture_body(builder_args.initial_health, shape_info, texture_info)
	instance_staticbody.reset_health()

#endregion
