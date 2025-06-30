class_name QuadrantBuilder extends Node2D

signal quadrant_hitted(fiat_gained: float)

#region Exports

@export_category("Settings")
@export_group("General")
@export var music: MusicDetails

@export_group("Size and Color")
@export var quadrant_size: Vector2i = Vector2i(250, 250)
@export var grid_size: Vector2i = Vector2i(16, 16)
@export var fracture_body_color: Color

#endregion

@onready var player: PlayerController = %Player
@onready var block_nodes: Node2D = %Quadrants
@onready var staticbody_template: PackedScene = preload("res://Scenes/QuadrantTerrain/StaticBody2DTemplate.tscn")

@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _rigid_bodies_parent: Node2D = %RigidBodiesParent
@onready var _pool_cut_visualizer: PoolFracture = $"../PoolFractureCutVisualizer"
@onready var _pool_fracture_shards: PoolFracture = $"../PoolFractureShards"
@onready var pool_fracture_bodies: PoolFracture = $"../Pool_FractureBodies"
@onready var _pool_fracture_bullet: PoolFracture = $"../Pool_FractureBullets"
@onready var block_core: BlockCore = %BlockCore
@onready var map_boundaries: StaticBody2D = %MapBoundaries
@onready var center: Area2D = %Center

var polygon_fracture: PolygonFracture
var _fracture_disabled: bool = false
var _cur_fracture_color: Color = fracture_body_color
var builder_args: LevelBuilderArgs
var _map_bounds: Rect2
var _grid_center: Vector2
var map_shape: Constants.MapShape = Constants.MapShape.Square
var _quadrant_positions: Array = []


#region Private Methods

func _ready() -> void:
	# _calculate_map_bounds()
	GameManager.pool_fracture_bullets = _pool_fracture_bullet
	GameManager.current_quadrant_builder = self
	AudioManager.change_music_clip(music)
	_init_builder()

func _physics_process(delta: float) -> void:
	if not enable_center_gravity: return

	## TODO - Fix gravity calculation
	if player and is_instance_valid(player):
		var gravity_force = _calculate_gravity_force(player.global_position)
		player.apply_gravity(gravity_force)

func _calculate_gravity_force(target_position: Vector2) -> Vector2:
    var direction = (_grid_center - target_position).normalized()
    var distance = target_position.distance_to(_grid_center)
    if distance < 0.001:
        return Vector2.ZERO
    var force_magnitude = gravity_strength / pow(distance, gravity_falloff)  # Simplified falloff

    return direction * force_magnitude


func _apply_gravity_to_objects(body1: Node2D, body2: Node2D, delta: float) -> void:
	var force_magnitude = pow(body2.global_position.distance_to(body1.global_position), gravity_falloff)
	
	var force = (body2.global_position\
	 - body1.global_position).normalized()\
	  * gravity_strength * body1.mass * body2.mass\
	   / force_magnitude

	body1.apply_central_force(force * delta)

func _apply_gravity_to_object(object: Node2D, object2: Node2D, _delta: float) -> void:
	if not object or not is_instance_valid(object):
		return
	
	var direction: Vector2 = object2.global_position - object.global_position
	var distance: float = direction.length()

	# Prevent extreme forces when very close to center
	if distance < 10: return 

	var force_magnitude: float = pow(distance, gravity_falloff)
	
	var force = (object2.global_position\
	 - object.global_position).normalized()\
	  * gravity_strength * object.mass * object2.mass\
	   / force_magnitude
	
	# Debug the calculation components
	print("Distance: ", distance, " Force magnitude: ", force_magnitude)
	
	# Apply gravity differently based on the object's type
	if object is RigidBody2D:
		object.apply_central_force(force)
	elif object is PlayerController:
		object.apply_central_force(force * _delta)

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

func _calculate_grid_center() -> void:
	_grid_center = Vector2(
		grid_size.x * quadrant_size.x / 2.0,
		grid_size.y * quadrant_size.y / 2.0
	)

func _create_boundary_walls() -> void:
	# Wall thickness
	var thickness: float = 75.0
	var horizontal_offset: float = 1.2

	# Calculate map center
	var center: Vector2 = Vector2(
		_map_bounds.position.x + _map_bounds.size.x/2,
		_map_bounds.position.y + _map_bounds.size.y/2
	)

	## Calculate adjusted width for top/bottom walls
	var horizontal_wall_width: float = _map_bounds.size.x * horizontal_offset + thickness * 2
	
	var wall_configs: Array = [
		# Top wall (adjusted width)
		{
			"size": Vector2(horizontal_wall_width, thickness),
			"position": center + Vector2(0, -_map_bounds.size.y/2 - thickness/2)
		},
		# Right wall
		{
			"size": Vector2(thickness, _map_bounds.size.y + thickness * 2),
			"position": center + Vector2(_map_bounds.size.x/2 + thickness/2, 0) * horizontal_offset
		},
		# Bottom wall (adjusted width)
		{
			"size": Vector2(horizontal_wall_width, thickness),
			"position": center + Vector2(0, _map_bounds.size.y/2 + thickness/2)
		},
		# Left wall
		{
			"size": Vector2(thickness, _map_bounds.size.y + thickness * 2),
			"position": center + Vector2(-_map_bounds.size.x/2 - thickness/2, 0) * horizontal_offset
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


## Initializes the builder with the given arguments.
func _init_builder() -> void:
        var builder_data: LevelBuilderArgs = GameManager.current_level_args
        builder_args = builder_data

        quadrant_size = Vector2i(builder_data.quadrant_size, builder_data.quadrant_size)
        grid_size = builder_data.grid_size
        map_shape = builder_data.map_shape
	
	polygon_fracture = PolygonFracture.new()
	_rng.randomize()
	
	var color := Color.WHITE
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	block_nodes.modulate = _cur_fracture_color
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


# func _calculate_map_bounds() -> void:
# 	var level_width: float = quadrant_size.x * grid_size.x
# 	var level_height: float = quadrant_size.y * grid_size.y
# 	var buffer: float = max(level_width, level_height) * 0.5  # 50% buffer zone
# 	_map_bounds = Rect2(
# 		Vector2(-buffer, -buffer),
# 		Vector2(level_width + buffer * 2, level_height + buffer * 2)
# 	)

# 	_create_boundary_walls()

# func _create_boundary_walls() -> void:
# 	# Wall thickness
# 	var thickness: float = 75.0
# 	var horizontal_offset: float = 1.2

# 	# Calculate map center
# 	var _center: Vector2 = Vector2(
# 		_map_bounds.position.x + _map_bounds.size.x/2,
# 		_map_bounds.position.y + _map_bounds.size.y/2
# 	)

# 	## Calculate adjusted width for top/bottom walls
# 	var horizontal_wall_width: float = _map_bounds.size.x * horizontal_offset + thickness * 2
	
# 	var wall_configs: Array = [
# 		# Top wall (adjusted width)
# 		{
# 			"size": Vector2(horizontal_wall_width, thickness),
# 			"position": _center + Vector2(0, -_map_bounds.size.y/2 - thickness/2)
# 		},
# 		# Right wall
# 		{
# 			"size": Vector2(thickness, _map_bounds.size.y + thickness * 2),
# 			"position": _center + Vector2(_map_bounds.size.x/2 + thickness/2, 0) * horizontal_offset
# 		},
# 		# Bottom wall (adjusted width)
# 		{
# 			"size": Vector2(horizontal_wall_width, thickness),
# 			"position": _center + Vector2(0, _map_bounds.size.y/2 + thickness/2)
# 		},
# 		# Left wall
# 		{
# 			"size": Vector2(thickness, _map_bounds.size.y + thickness * 2),
# 			"position": _center + Vector2(-_map_bounds.size.x/2 - thickness/2, 0) * horizontal_offset
# 		}
# 	]

# 	for config in wall_configs:
# 		var wall: StaticBody2D = StaticBody2D.new()
# 		var collision_shape: CollisionShape2D = CollisionShape2D.new()
# 		var rect_shape: RectangleShape2D = RectangleShape2D.new()

# 		rect_shape.size = config.size
# 		collision_shape.shape = rect_shape
# 		wall.position = config.position

# 		wall.add_child(collision_shape)
# 		map_boundaries.add_child(wall)

#endregion

## Handles the fracturing of the source polygon at the given position.
## @param source The source polygon to be fractured.
## @param cut_pos The position where the cut occurred.
## @param cut_shape The shape of the cut.
## @param cut_rot The rotation of the cut.
## @param fade_speed The speed at which the visualizer fades.
func fracture_quadrant_on_collision(pos : Vector2, other_body: FracturableStaticBody2D, bullet_launch_velocity:float = 410.0, bullet_damage: float = 25.0, bullet_speed: float = 500.0) -> void:
	var p = bullet_launch_velocity / bullet_speed
	var cut_shape: PackedVector2Array = polygon_fracture.generateRandomPolygon(Vector2(100,50) * p, Vector2(8,32), Vector2.ZERO)
	_spawn_cut_visualizers(pos, cut_shape, 10.0)
	
	if !other_body.take_damage(bullet_damage):
		return
	
	if _fracture_disabled: return
	_fracture_disabled = true
	_cut_polygons(other_body, pos, cut_shape, 45.0, 10.0)
	other_body.random_drops.spawn_drops(1)
	
	set_deferred("_fracture_disabled", false)

## Fractures the quadrant block core,
## which at the same time will mine a bitcoin block.
## @param bullet_damage The damage to deal to the block core.
## @param miner The miner that will mine the block.
## @param instakill Whether the block core should be instakilled.
func fracture_block_core(bullet_damage: float, miner: String = "Player", instakill: bool = false) -> void:
	if _fracture_disabled: return
	_fracture_disabled = true
	
	block_core.fracture(builder_args.block_core_cuts_delaunay, builder_args.block_core_cut_min_area, bullet_damage, _cur_fracture_color, instakill, miner)
	
	set_deferred("_fracture_disabled", false)

func _is_cell_in_shape(cell: Vector2i) -> bool:
        var cell_center = (cell.to_vector2() + Vector2(0.5, 0.5)) * quadrant_size
        match map_shape:
                Constants.MapShape.Circle:
                        var radius = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
                        return cell_center.distance_to(_grid_center) <= radius
                Constants.MapShape.Diamond:
                        var rx = grid_size.x * quadrant_size.x / 2.0
                        var ry = grid_size.y * quadrant_size.y / 2.0
                        return abs(cell_center.x - _grid_center.x) / rx + abs(cell_center.y - _grid_center.y) / ry <= 1.0
                _:
                        return true

func _initialize_grid_of_blocks(initial_health: float) -> void:
        _quadrant_positions.clear()
        for i in range(grid_size.x):
                for j in range(grid_size.y):
                        var cell := Vector2i(i, j)
                        if not _is_cell_in_shape(cell):
                                continue
                        var block: FracturableStaticBody2D = staticbody_template.instantiate()
                        block_nodes.add_child(block)
                        block.rectangle_size = Vector2(builder_args.quadrant_size, builder_args.quadrant_size)
                        block.placed_in_level = true
                        var pos = Vector2(i * quadrant_size.x, j * quadrant_size.y)
                        block.position = pos
                        _quadrant_positions.append(pos)
                        block.setFractureBody(initial_health, builder_args.quadrant_texture, builder_args.hit_sound, builder_args.normal_texture)
        _calculate_map_bounds()
        _initialize_block_core()

func _set_player_position() -> void:
	## Set the player position to a random position within the grid of blocks with a little offset
	## This is to avoid the player to be spawned in the same position as the block core or inside a block
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
	player.global_position = spawn_point

func _initialize_block_core():
        var bounds: Rect2 = block_core.get_bounding_square()
        var core_size: float = bounds.size.x

        var padding: float = core_size * 0.5
        block_core.global_position = _random_position_within_shape(padding)
        block_core.health.set_max_health(builder_args.initial_health * 2.0) # May change to scale exponentially
        block_core.set_hit_sound_effect(builder_args.hit_sound, false)

func _point_inside_shape(point: Vector2) -> bool:
        match map_shape:
                Constants.MapShape.Circle:
                        var radius = min(grid_size.x, grid_size.y) * quadrant_size.x / 2.0
                        return point.distance_to(_grid_center) <= radius
                Constants.MapShape.Diamond:
                        var rx = grid_size.x * quadrant_size.x / 2.0
                        var ry = grid_size.y * quadrant_size.y / 2.0
                        return abs(point.x - _grid_center.x) / rx + abs(point.y - _grid_center.y) / ry <= 1.0
                _:
                        return Rect2(Vector2.ZERO, quadrant_size * grid_size).has_point(point)

func _random_position_within_shape(padding: float) -> Vector2:
        var min_pos: Vector2 = Vector2(padding, padding)
        var max_pos: Vector2 = quadrant_size * grid_size - Vector2(padding, padding)
        var attempts := 0
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
	
	var cut_fracture_info: Dictionary = polygon_fracture.cutFracture(source_polygon, cut_shape, source_transform, cut_transform, 1000.0, 500.0, 100.0, 21)
	
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

## Spawns little polygons shards (for visual effects) at the position where the collision happened.
## The shards will have a random lifetime and mass based on the area of the original polygon that was fractured.
## The shards will shrink and disappear after the lifetime is over.
## @param texture_info The dictionary containing the texture information.
## @param new_mass The new mass of the shard.
## @param life_time The lifetime of the shard.
func _spawn_fracture_shards(fracture_shard : Dictionary, texture_info : Dictionary, new_mass : float, life_time : float) -> void:
	var instance_fbody = _pool_fracture_shards.getInstance()
	if not instance_fbody:
		return
	
	instance_fbody.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), life_time)
	instance_fbody.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
	instance_fbody.setMass(new_mass)

## Spawns a little polygon cut that serves as feedback to the player on where the collision happened.
## @param pos The position where the cut occurred.
## @param poly The shape of the cut.
## @param fade_speed The speed at which the visualizer fades.
func _spawn_cut_visualizers(pos : Vector2, poly : PackedVector2Array, fade_speed : float) -> void:
	var instance_visualizers = _pool_cut_visualizer.getInstance()
	instance_visualizers.spawn(pos, fade_speed)
	instance_visualizers.setPolygon(poly)

## Spawn a static body at the collision position with the ramaining shape of the original polygon
func _spawn_staticbody(shape_info : Dictionary, color : Color, texture_info : Dictionary) -> void:
	var instance_staticbody: FracturableStaticBody2D = staticbody_template.instantiate()
	_rigid_bodies_parent.add_child(instance_staticbody)
	instance_staticbody.global_position = shape_info.spawn_pos
	instance_staticbody.global_rotation = shape_info.spawn_rot
	instance_staticbody.set_polygon(shape_info.centered_shape)
	instance_staticbody.self_modulate = color
	instance_staticbody.set_fracture_body(builder_args.initial_health, shape_info, texture_info, builder_args.hit_sound)
