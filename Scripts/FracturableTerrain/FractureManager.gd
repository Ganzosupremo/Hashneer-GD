class_name FractureManager extends Node2D
## Manages all fracturing and destruction logic for terrain blocks.
##
## This class handles polygon fracturing, damage processing, shard spawning,
## and manages the object pools for fracture effects.

signal block_fractured(position: Vector2, ore_type: OreDetails.OreType)

@export_category("Fracture Settings")
@export var fracture_body_color: Color = Color.WHITE

@export_category("Pool References")
@export var pool_cut_visualizer: PoolFracture
@export var pool_fracture_shards: PoolFracture
@export var pool_fracture_bodies: PoolFracture
@export var rigid_bodies_parent: Node2D

@export_category("Templates")
@export var terrain_block_template: PackedScene

@export_category("Mining Mode")
@export var mining_mode_enabled: bool = false
@export var digital_ambiance: DigitalAmbiance

var _polygon_fracture: PolygonFracture
var _fracture_disabled: bool = false
var _cur_fracture_color: Color
var _rng: RandomNumberGenerator
var _initial_health: float = 100.0

func _ready() -> void:
	_polygon_fracture = PolygonFracture.new()
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_randomize_fracture_color()

func initialize(initial_health: float) -> void:
	_initial_health = initial_health
	_randomize_fracture_color()

func _randomize_fracture_color() -> void:
	var color: Color = Color.WHITE
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	
	if rigid_bodies_parent:
		rigid_bodies_parent.modulate = _cur_fracture_color

func get_fracture_color() -> Color:
	return _cur_fracture_color

## Handles the fracturing of a terrain block at the given position.
## [param pos]: The global position where the fracture occurs.
## [param other_body]: The FracturableStaticBody2D that is being fractured.
## [param bullet_launch_velocity]: The launch velocity of the bullet.
## [param bullet_damage]: The damage dealt by the bullet.
## [param bullet_speed]: The speed of the bullet.
func fracture_on_collision(pos: Vector2, other_body: FracturableStaticBody2D, bullet_launch_velocity: float = 410.0, bullet_damage: float = 25.0, bullet_speed: float = 500.0) -> void:
	var p: float = bullet_launch_velocity / bullet_speed
	var cut_shape: PackedVector2Array = _polygon_fracture.generateRandomPolygon(Vector2(100, 50) * p, Vector2(8, 32), Vector2.ZERO)
	_spawn_cut_visualizers(pos, cut_shape, 10.0)
	
	if not other_body.take_damage(bullet_damage):
		return
	
	if _fracture_disabled:
		return
	_fracture_disabled = true
	_cut_polygons(other_body, pos, cut_shape, 45.0, 10.0)
	
	if mining_mode_enabled and other_body is TerrainBlock:
		other_body.random_drops.spawn_drops(5)
		if digital_ambiance:
			digital_ambiance.create_scan_burst(pos)
		var ore_type: OreDetails.OreType = other_body.get_meta("ore_type", OreDetails.OreType.DIRT)
		block_fractured.emit(pos, ore_type)
	else:
		other_body.random_drops.spawn_drops(1)
	
	set_deferred("_fracture_disabled", false)

## Cut polygons and spawn resulting pieces.
func _cut_polygons(source: FracturableStaticBody2D, cut_pos: Vector2, cut_shape: PackedVector2Array, cut_rot: float, fade_speed: float = 2.0) -> void:
	_spawn_cut_visualizers(cut_pos, cut_shape, fade_speed)
	var source_polygon: PackedVector2Array = source.get_polygon()
	var total_area: float = PolygonLib.getPolygonArea(source_polygon)
	
	var source_transform: Transform2D = source.get_global_transform()
	var cut_transform := Transform2D(cut_rot, cut_pos)
	
	var s_mass: float = 1.0
	
	var cut_fracture_info: Dictionary = _polygon_fracture.cutFracture(source_polygon, cut_shape, source_transform, cut_transform, 1000.0, 500.0, 100.0, 21)
	
	if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
		return
	
	for fracture in cut_fracture_info.fractures:
		for fracture_shard in fracture:
			var area_p: float = fracture_shard.area / total_area
			var rand_lifetime: float = _rng.randf_range(1.5, 2.5) + 2.0 * area_p
			_spawn_fracture_shards(fracture_shard, source.getTextureInfo(), s_mass * area_p, rand_lifetime)
	
	for shape in cut_fracture_info.shapes:
		if source is TerrainBlock:
			call_deferred("_spawn_staticbody", shape, source.self_modulate, source.getTextureInfo(), source.getOreInfo())
		else:
			call_deferred("_spawn_staticbody", shape, _cur_fracture_color, source.getTextureInfo())
	source.queue_free()

## Spawn fracture shards for visual effects.
func _spawn_fracture_shards(fracture_shard: Dictionary, texture_info: Dictionary, new_mass: float, life_time: float) -> void:
	if not pool_fracture_shards:
		return
	var instance_fbody = pool_fracture_shards.getInstance()
	if not instance_fbody:
		return
	
	instance_fbody.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), life_time)
	instance_fbody.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
	instance_fbody.setMass(new_mass)

## Spawn cut visualizers for feedback.
func _spawn_cut_visualizers(pos: Vector2, poly: PackedVector2Array, fade_speed: float) -> void:
	if not pool_cut_visualizer:
		return
	var instance_visualizers = pool_cut_visualizer.getInstance()
	if instance_visualizers:
		instance_visualizers.spawn(pos, fade_speed)
		instance_visualizers.setPolygon(poly)

## Spawn a static body with the remaining shape after fracturing.
func _spawn_staticbody(shape_info: Dictionary, color: Color, texture_info: Dictionary, ore_info: Dictionary = {}) -> void:
	if not terrain_block_template or not rigid_bodies_parent:
		return
	
	var instance_staticbody: TerrainBlock = terrain_block_template.instantiate()
	rigid_bodies_parent.add_child(instance_staticbody)
	instance_staticbody.global_position = shape_info.spawn_pos
	instance_staticbody.global_rotation = shape_info.spawn_rot
	instance_staticbody.set_polygon(shape_info.centered_shape)
	instance_staticbody.self_modulate = color
	
	if ore_info.size() > 0:
		var ore_type: OreDetails.OreType = ore_info.get("ore_type", OreDetails.OreType.DIRT)
		var ore_data: OreDetails = ore_info.get("ore_data", null)
		var depth_layer: int = ore_info.get("depth_layer", 0)
		var health: float = ore_info.get("health", _initial_health)
		var terrain_block_args: TerrainBlock.TerrainBlockArgs = TerrainBlock.TerrainBlockArgs.new(ore_type, ore_data, depth_layer, health)
		instance_staticbody.setup(terrain_block_args, texture_info)
	
	instance_staticbody.set_fracture_body(_initial_health, shape_info, texture_info)
	instance_staticbody.reset_health()
