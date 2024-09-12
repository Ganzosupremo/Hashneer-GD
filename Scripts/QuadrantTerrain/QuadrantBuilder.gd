class_name QuadrantBuilder extends Node2D

signal map_builded()

@export_category("Quadrant Variables")
@export var quadrants_initial_health: float 
@export var resource_droprate_multiplier: float = 1.5

@export var quadrant_size: Vector2i = Vector2i(250, 250)
@export var grid_size: Vector2i = Vector2i(16, 16)
@export var fracture_body_color: Color

@export var cuts: int = 50
@export var min_area: float = 100.0

@onready var player: PlayerController = %Player
@onready var quadrants: Node2D = %Quadrants
@onready var quadrant_scene: PackedScene = preload("res://Scenes/QuadrantTerrain/Quadrant.tscn")
@onready var staticbody_template = preload("res://Scenes/QuadrantTerrain/StaticBody2DTemplate.tscn")

@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _rigid_bodies_parent: Node2D = %RigidBodiesParent
@onready var _pool_cut_visualizer: PoolFracture = $"../Pool_FractureCutVisualizer"
@onready var _pool_fracture_shards: PoolFracture = $"../Pool_FractureShards"
@onready var _pool_fracture_bodies: PoolFracture = $"../Pool_FractureBodies"
@onready var _pool_fracture_bullet: PoolFracture = $"../Pool_FractureBullets"
@onready var block_core: BlockCore = %BlockCore

var polygon_fracture: PolygonFracture
var _fracture_disabled:bool = false
var _cur_fracture_color: Color = fracture_body_color
var builder_args: QuadrantBuilderArgs
static var instance: QuadrantBuilder = self

func _ready() -> void:
	instance = self
	_init_builder()

func _init_builder() -> void:
	print("Builder Initialized")
	var data: QuadrantBuilderArgs = GameManager.builder_args
	builder_args = data
	
	quadrant_size = Vector2i(data.quadrant_size, data.quadrant_size)
	grid_size = data.grid_size
	
	cuts = data.block_core_cuts_delaunay
	min_area = data.block_core_cut_min_area
	
	quadrants_initial_health = data.initial_health
	resource_droprate_multiplier = data.drop_rate_multiplier
	
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

"""Fractures the quadrant at the specified position"""
func fracture_quadrant_on_collision(pos : Vector2, other_body: FracturableStaticBody2D, bullet_launch_velocity:float = 410.0, bullet_damage: float = 25.0, bullet_speed: float = 500.0) -> void:
	var p = bullet_launch_velocity / bullet_speed
	var cut_shape: PackedVector2Array = polygon_fracture.generateRandomPolygon(Vector2(100,50) * p, Vector2(8,32), Vector2.ZERO)
	_spawn_cut_visualizers(pos, cut_shape, 10.0)
	
	if !other_body.take_damage(bullet_damage, false):
		return
	
	if _fracture_disabled: return
	
	_cut_polygons(other_body, pos, cut_shape, 45.0, 10.0)
	BitcoinWallet.add_fiat(5000.0 * builder_args.drop_rate_multiplier)
	
	_fracture_disabled = true
	set_deferred("_fracture_disabled", false)

func fracture_all(other_body: Node2D, bullet_damage: float) -> void:
	if _fracture_disabled: return

	block_core.fracture_all(other_body, cuts,  min_area, bullet_damage, _cur_fracture_color)
	
	_fracture_disabled = true
	set_deferred("_fracture_disabled", false)

func _generate_quadrants(quadrants_initial_health: float) -> void:
	for i in range(grid_size.x):
		for j in range(grid_size.y):
			var quadrant: FracturableStaticBody2D = quadrant_scene.instantiate()
			quadrants.add_child(quadrant)
			quadrant.rectangle_size = Vector2(250,250)
			quadrant.placed_in_level = true
			quadrant.position = Vector2(i * quadrant_size.x * 1.25, j * quadrant_size.y * 1.25)
			quadrant.set_initial_health(quadrants_initial_health)
	
	_set_block_core_position()

func _set_player_position() -> void:
	var children: Array = get_children()
	player.global_position = children[_rng.randi_range(0, len(children)-1)].global_position

func _set_block_core_position():
	var center: Vector2 = quadrant_size * grid_size * 0.5
	
	block_core.pass_level_index(builder_args.level_index)
	block_core.global_position = center

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
			_spawn_fracture_body(fracture_shard, source.getTextureInfo(), s_mass * area_p, rand_lifetime)
	
	for shape in cut_fracture_info.shapes:
		call_deferred("_spawn_staticbody", shape, source.modulate, source.getTextureInfo())
	
	source.queue_free()

"""Spawns little polygons at the position where the collision happened"""
func _spawn_fracture_body(fracture_shard : Dictionary, texture_info : Dictionary, new_mass : float, life_time : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), life_time)
	instance.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
	instance.setMass(new_mass)

"""Spawns a little polygon that serve as feedback to the player on where the collision happened"""
func _spawn_cut_visualizers(pos : Vector2, poly : PackedVector2Array, fade_speed : float) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(pos, fade_speed)
	instance.setPolygon(poly)

func _spawn_staticbody(shape_info : Dictionary, color : Color, texture_info : Dictionary) -> void:
	var instance = staticbody_template.instantiate()
	_rigid_bodies_parent.add_child(instance)
	instance.global_position = shape_info.spawn_pos
	instance.global_rotation = shape_info.spawn_rot
	instance.set_polygon(shape_info.centered_shape)
	instance.modulate = color
	instance.set_initial_health(quadrants_initial_health)
	instance.setTexture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))

static func get_instance() -> QuadrantBuilder:
	return instance
