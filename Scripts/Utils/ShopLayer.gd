class_name ShopLayer extends Node2D
## Visual and functional layer for the mining shop area (safe area)

## Platform scene for instancing
@onready var platform_scene: PackedScene = preload("res://Scenes/Utils/Platform.tscn")

@export var layer_height: float = 500.0
@export var background_color: Color = Color(0.15, 0.15, 0.25, 1.0)  # Dark blue-gray
@export var platform_color: Color = Color(0.3, 0.3, 0.4, 1.0)  # Lighter blue-gray
@export var walkway_width_ratio: float = 0.45  # Portion of terrain width used as safe platform
@export var walkway_max_ratio: float = 0.65  # Prevent platform from covering entire width
@export var walkway_min_width: float = 300.0
@export var platform_height_offset: float = 25.0
const PLATFORM_THICKNESS: float = 50.0

var _shop_spawn_point: Marker2D
var _player_spawn_point: Marker2D
var _layer_width: float = 1000.0  # Will be set by terrain width
var _platform_width: float = 500.0

## Initialize with terrain width to match exactly
func initialize(terrain_width: float) -> void:
	_clear_layer()
	_layer_width = terrain_width

	var desired_width: float = terrain_width * walkway_width_ratio
	var max_allowed: float = terrain_width * walkway_max_ratio
	_platform_width = clamp(desired_width, walkway_min_width, max_allowed)
	var max_with_opening: float = max(terrain_width - 50.0, walkway_min_width)
	_platform_width = clamp(_platform_width, walkway_min_width, max_with_opening)
	_platform_width = min(_platform_width, terrain_width)

	_create_background()
	_create_platform()
	_create_spawn_points()
	_add_ambient_effects()


func _clear_layer() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_shop_spawn_point = null
	_player_spawn_point = null


func _create_background() -> void:
   # Main bg
	var background = ColorRect.new()
	background.name = "Background"
	background.color = background_color
	background.size = Vector2(_layer_width, layer_height)
	background.position = Vector2(0, -layer_height)
	add_child(background)

	# Digital grid pattern
	var grid = Node2D.new()
	grid.name = "GridPattern"
	background.add_child(grid)

	# Horizontal lines
	for i in range(0, int(layer_height), 25):
		var line = Line2D.new()
		line.add_point(Vector2(0, i))
		line.add_point(Vector2(_layer_width, i))
		line.default_color = Color(0.3, 0.5, 0.7, 0.3)
		line.width = 1.0
		grid.add_child(line)

	# Vertical lines
	for i in range(0, int(_layer_width), 25):
		var line = Line2D.new()
		line.add_point(Vector2(i, 0))
		line.add_point(Vector2(i, layer_height))
		line.default_color = Color(0.3, 0.5, 0.7, 0.3)
		line.width = 1.0
		grid.add_child(line)

func _create_platform() -> void:
	# Center platform
	var platform: StaticBody2D = platform_scene.instantiate()
	platform.name = "ShopPlatformCenter"
	add_child(platform)

	var collision: CollisionShape2D = platform.get_node_or_null("Collision")
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(_platform_width, PLATFORM_THICKNESS)
	collision.shape = shape
	collision.position = Vector2.ZERO

	# Position platform at bottom of shop layer (just above Y=0, mining starts here)
	platform.position = Vector2(_layer_width / 2, -platform_height_offset)

	# Visual
	var visual: ColorRect = platform.get_node_or_null("Visual")
	visual.color = platform_color
	visual.size = shape.size
	visual.position = -shape.size / 2

	_add_platform_details(visual)
	
	# Left platform
	var left_platform_width: float = _layer_width * 0.10  # 10% of terrain width
	_create_side_platform("ShopPlatformLeft", left_platform_width, left_platform_width / 2)
	
	# Right platform
	var right_platform_width: float = _layer_width * 0.10  # 10% of terrain width
	_create_side_platform("ShopPlatformRight", right_platform_width, _layer_width - right_platform_width / 2)

func _create_side_platform(platform_name: String, platform_width: float, x_position: float) -> void:
	var platform: StaticBody2D = platform_scene.instantiate()
	platform.name = platform_name
	add_child(platform)

	var collision: CollisionShape2D = platform.get_node_or_null("Collision")
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(platform_width, PLATFORM_THICKNESS)
	collision.shape = shape
	collision.position = Vector2.ZERO

	# Position at same height as center platform
	platform.position = Vector2(x_position, -platform_height_offset)

	# Visual
	var visual: ColorRect = platform.get_node_or_null("Visual")
	visual.color = platform_color
	visual.size = shape.size
	visual.position = -shape.size / 2

	_add_platform_details(visual)

func _add_platform_details(visual: ColorRect) -> void:
	# Add panel lines
	for i in range(0, int(visual.size.x), 100):
		var line = Line2D.new()
		line.add_point(Vector2(i, 0))
		line.add_point(Vector2(i, visual.size.y))
		line.default_color = Color(0.5, 0.7, 1.0, 0.4)
		line.width = 2.0
		visual.add_child(line)
	
	# Add rivet sprites
	for i in range(0, int(visual.size.x), 100):
		var rivet = ColorRect.new()
		rivet.color = Color(0.7, 0.8, 1.0, 0.6)
		rivet.size = Vector2(8, 8)
		rivet.position = Vector2(i - 4, 10)
		visual.add_child(rivet)

		var rivet2 = ColorRect.new()
		rivet2.color = Color(0.7, 0.8, 1.0, 0.6)
		rivet2.size = Vector2(8, 8)
		rivet2.position = Vector2(i - 4, visual.size.y - 18)
		visual.add_child(rivet2)

func _create_spawn_points() -> void:
	# Player spawnpoint (on the platform, left side)
	var platform_top: float = -platform_height_offset - PLATFORM_THICKNESS / 2
	_player_spawn_point = Marker2D.new()
	_player_spawn_point.name = "PlayerSpawnPoint"
	_player_spawn_point.position = Vector2(_layer_width * 0.5 - _platform_width * 0.3, platform_top - 20.0)
	add_child(_player_spawn_point)

	# Shop spawnpoint (on the platform, right side)
	_shop_spawn_point = Marker2D.new()
	_shop_spawn_point.name = "ShopSpawnPoint"
	_shop_spawn_point.position = Vector2(_layer_width * 0.5 + _platform_width * 0.3, platform_top - 5.0)
	add_child(_shop_spawn_point)

func _add_ambient_effects() -> void:
	var particles: GPUParticles2D = GPUParticles2D.new()
	particles.name = "AmbientParticles"
	particles.amount = 50
	particles.lifetime = 5.0
	particles.position = Vector2(_layer_width / 2, -layer_height / 2)

	var p_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_material.direction = Vector3(0, 1, 0)
	p_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_material.emission_box_extents = Vector3(_layer_width / 2, layer_height / 2, 0)
	p_material.initial_velocity_min = 10.0
	p_material.initial_velocity_max = 30.0
	p_material.gravity = Vector3(0, 5, 0)
	p_material.scale_min = 1.0
	p_material.scale_max = 3.0
	p_material.color = Color(0.5, 0.7, 1.0, 0.2)

	particles.process_material = p_material
	add_child(particles)
	particles.emitting = true

func get_player_spawn_position() -> Vector2:
	return _player_spawn_point.global_position

func get_shop_spawn_position() -> Vector2:
	return _shop_spawn_point.global_position
