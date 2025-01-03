class_name QuadrantBuilder extends Node2D

signal quadrant_hitted(fiat_gained: float)

@export_category("Settings")
@export_group("General")
@export var quadrants_initial_health: float 
@export var resource_droprate_multiplier: float = 1.5

@export_group("Size and Color")
@export var quadrant_size: Vector2i = Vector2i(250, 250)
@export var grid_size: Vector2i = Vector2i(16, 16)
@export var fracture_body_color: Color

@export_group("Block Core Variables")
@export var block_core_cuts: int = 50
@export var min_area: float = 100.0

@onready var player: PlayerController = %Player
@onready var quadrants: Node2D = %Quadrants
@onready var quadrant_scene: PackedScene = preload("res://Scenes/QuadrantTerrain/Quadrant.tscn")
@onready var staticbody_template: PackedScene = preload("res://Scenes/QuadrantTerrain/StaticBody2DTemplate.tscn")

@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _rigid_bodies_parent: Node2D = %RigidBodiesParent
@onready var _pool_cut_visualizer: PoolFracture = $"../Pool_FractureCutVisualizer"
@onready var _pool_fracture_shards: PoolFracture = $"../Pool_FractureShards"
@onready var pool_fracture_bodies: PoolFracture = $"../Pool_FractureBodies"
@onready var _pool_fracture_bullet: PoolFracture = $"../Pool_FractureBullets"
@onready var block_core: BlockCore = %BlockCore
#@onready var bitcoin_wallet: BWallet = %BWallet

var polygon_fracture: PolygonFracture
var _fracture_disabled:bool = false
var _cur_fracture_color: Color = fracture_body_color
var builder_args: QuadrantBuilderArgs
static var instance: QuadrantBuilder = self

func _ready() -> void:
	GameManager.pool_fracture_bullets = _pool_fracture_bullet
	GameManager.current_quadrant_builder = self
	_init_builder()

func _init_builder() -> void:
	var builder_data: QuadrantBuilderArgs = GameManager.builder_args
	builder_args = builder_data
	
	quadrant_size = Vector2i(builder_data.quadrant_size, builder_data.quadrant_size)
	grid_size = builder_data.grid_size
	
	block_core_cuts = builder_data.block_core_cuts_delaunay
	min_area = builder_data.block_core_cut_min_area
	
	quadrants_initial_health = builder_data.initial_health
	resource_droprate_multiplier = builder_data.drop_rate_multiplier
	
	polygon_fracture = PolygonFracture.new()
	_rng.randomize()
	
	var color := Color.WHITE
	color.s = fracture_body_color.s
	color.v = fracture_body_color.v
	color.h = _rng.randf()
	_cur_fracture_color = color
	quadrants.modulate = _cur_fracture_color
	
	_set_player_position()
	
	_generate_quadrants(quadrants_initial_health)

## Handles the fracturing of the source polygon at the given position.
## @param source The source polygon to be fractured.
## @param cut_pos The position where the cut occurred.
## @param cut_shape The shape of the cut.
## @param cut_rot The rotation of the cut.
## @param fade_speed The speed at which the visualizer fades.
func fracture_quadrant_on_collision(pos : Vector2, other_body: FracturableStaticBody2D, bullet_launch_velocity:float = 410.0, bullet_damage: float = 25.0, bullet_speed: float = 500.0) -> void:
	var p = bullet_launch_velocity / bullet_speed
	var cut_shape: PackedVector2Array = polygon_fracture.generateRandomPolygon(Vector2(100,50) * p, Vector2(8,32), Vector2.ZERO)
	other_body.play_sound_on_hit()
	_spawn_cut_visualizers(pos, cut_shape, 10.0)
	
	if !other_body.take_damage(bullet_damage):
		return
	
	if _fracture_disabled: return
	
	_cut_polygons(other_body, pos, cut_shape, 45.0, 10.0)
	
	var fiat_gained_on_collision: float = 5000.0 * builder_args.drop_rate_multiplier
	emit_signal("quadrant_hitted", fiat_gained_on_collision)
	BitcoinWallet.add_fiat(fiat_gained_on_collision)
	
	_fracture_disabled = true
	set_deferred("_fracture_disabled", false)

"""Fractures the quadrant block,
which at the same time will mine a bitcoin block"""
func fracture_all(other_body: FracturableStaticBody2D, bullet_damage: float, miner: String = "Player", instakill: bool = false) -> void:
	if _fracture_disabled: return
	
	other_body.play_sound_on_hit()
	block_core.fracture_all(other_body, block_core_cuts, min_area, bullet_damage, _cur_fracture_color, instakill, miner)
	
	_fracture_disabled = true
	set_deferred("_fracture_disabled", false)

func _generate_quadrants(initial_health: float) -> void:
	for i in range(grid_size.x):
		for j in range(grid_size.y):
			var quadrant: FracturableStaticBody2D = quadrant_scene.instantiate()
			quadrants.add_child(quadrant)
			quadrant.rectangle_size = Vector2(builder_args.quadrant_size, builder_args.quadrant_size)
			quadrant.placed_in_level = true
			quadrant.position = Vector2(i * quadrant_size.x, j * quadrant_size.y)
			quadrant.set_fracture_body(initial_health, builder_args.quadrant_texture, builder_args.hit_sound)
	_set_quadrant_core()

func _set_player_position() -> void:
	## Set the player position to a random position within the grid of quadrants with a little offset
	## This is to avoid the player to be spawned in the same position as the block core or inside a quadrant
	var offset: Vector2 = Vector2(20, 20)
	var max_limit: float = max(quadrant_size.x * grid_size.x, quadrant_size.y * grid_size.y) * 1.1
	
	var random_x: float
	var random_y: float
	
	# Ensure the player spawns outside the grid boundaries but within the max limit
	if _rng.randf() < 0.5:
		random_x = clamp(_rng.randi_range(-1, 0) * quadrant_size.x - offset.x, -max_limit, max_limit)
	else:
		random_x = clamp(_rng.randi_range(grid_size.x, grid_size.x + 1) * quadrant_size.x + offset.x, -max_limit, max_limit)
	
	if _rng.randf() < 0.5:
		random_y = clamp(_rng.randi_range(-1, 0) * quadrant_size.y - offset.y, -max_limit, max_limit)
	else:
		random_y = clamp(_rng.randi_range(grid_size.y, grid_size.y + 1) * quadrant_size.y + offset.y, -max_limit, max_limit)
	
	player.global_position = Vector2(random_x, random_y)

func _set_quadrant_core():
	var center: Vector2 = quadrant_size * grid_size * 0.5
	block_core.global_position = center
	block_core.set_hit_sound_effect(builder_args.hit_sound, false)

func _cut_polygons(source: Node2D, cut_pos: Vector2, cut_shape : PackedVector2Array, cut_rot : float, fade_speed : float = 2.0) -> void:
	_spawn_cut_visualizers(cut_pos, cut_shape, fade_speed)
	var source_polygon: PackedVector2Array = source.get_polygon()
	var total_area: float = PolygonLib.getPolygonArea(source_polygon)
	
	var source_transform: Transform2D = source.get_global_transform()
	var cut_transform := Transform2D(cut_rot, cut_pos)
	
	var s_mass : float = 0.1
	
	var cut_fracture_info: Dictionary = polygon_fracture.cutFracture(source_polygon, cut_shape, source_transform, cut_transform, 1000.0, 500.0, 100.0, 21)
	
	if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
		print('empty dictionary')
		return
	
	for fracture in cut_fracture_info.fractures:
		for fracture_shard in fracture:
			var area_p : float = fracture_shard.area / total_area
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
	instance_staticbody.set_fracture_body(quadrants_initial_health, builder_args.quadrant_texture, builder_args.hit_sound)
	instance_staticbody.setTexture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))

static func get_instance() -> QuadrantBuilder:
	return instance
