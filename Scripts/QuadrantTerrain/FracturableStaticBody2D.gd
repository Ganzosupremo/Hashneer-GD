## A class that represents a destructible static body in 2D space.
## It can be created with different shapes and supports texture customization,
## health management, and collision detection.
class_name FracturableStaticBody2D extends StaticBody2D

@onready var _polygon2d: Polygon2D = $Polygon2D
@onready var _line2d: Line2D = $Polygon2D/Line2D
@onready var _col_polygon2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var _rng: RandomNumberGenerator= RandomNumberGenerator.new()
@onready var health: HealthComponent = %Health
@onready var _hit_sound_component: SoundEffectComponent = %HitSoundComponent
@onready var light_occluder_2d: LightOccluder2D = $LightOccluder2D
@onready var random_drops: RandomDrops = $RandomDrops

#region Properties

@export_group("General")
## If true, the body will be initialized with its shape when placed in level
@export var placed_in_level: bool = false
## If true, randomizes the texture scale, rotation and offset
@export var randomize_texture_properties: bool = true
## The texture to be applied to the polygon
@export var poly_texture: Texture2D
## Sound effect to play when the body is hit
@export var hit_sound_effect: SoundEffectDetails
## Sound effect to play when the body is destroyed
@export var sound_effect_on_destroy: SoundEffectDetails
@export_range(0.0, 100.0, 0.5, "or_greater") var mass: float = 10.0

enum PolygonShape { Circular, Rectangular, Beam, SuperEllipse, SuperShape}
@export_group("Shape")
@export var polygon_shape: Constants.PolygonShape

@export_group("Circular Shape", "cir_")
@export var cir_radius: float = 0.0
@export var cir_smoothing : int = 1 # (int, 0, 5, 1)

@export_group("Rectangle Shape", "rectangle_")
@export var rectangle_size : Vector2 = Vector2.ZERO
@export var rectangle_local_center: Vector2 = Vector2.ZERO

@export_group("Beam Shape", "beam_")
@export var beam_dir : Vector2 = Vector2.ZERO
@export var beam_distance : float = 0
@export var beam_start_width : float = 0
@export var beam_end_width : float = 0
@export var beam_start_point_local: Vector2 = Vector2.ZERO

@export_group("Super Ellipse and Super Shape Common Vars", "s_")
@export var s_p_number : int = 0
@export var s_a : float = 0
@export var s_b : float = 0
@export var s_start_angle_deg : float = 0.0
@export var s_max_angle_deg : float = 360.0
@export var s_offset := Vector2.ZERO

@export_group("Super Ellipse Shape", "e_")
@export var e_n : float = 0

@export_group("Super Shape", "")
@export_range(0.0, 30.0, 0.05) var min_m: float = 0.0
@export_range(0.0, 30.0, 0.05) var m: float = 20.0
@export_range(0.0, 1.0, 0.05) var min_n1: float = 0
@export_range(0.0, 1.0, 0.05) var n1 : float = 0
@export_range(0.0, 1.0, 0.05) var min_n2: float = 0
@export_range(0.0, 1.0, 0.05) var n2 : float = 0
@export_range(0.0, 1.0, 0.05) var min_n3: float = 0
@export_range(0.0, 1.0, 0.05) var n3 : float = 0

#endregion

var destroyed: bool = false

func _ready() -> void:
	health.zero_health.connect(_on_zero_health)
	_rng.randomize()
	if placed_in_level:
		var poly = create_polygon_shape()
		
		setPolygon(poly)
		_apply_random_texture_properties()

## Recreates the polygon shape with current parameters
func recreate_polygon_shape() -> void:
	var poly = create_polygon_shape()
	setPolygon(poly)
	_apply_random_texture_properties()

## Creates a polygon shape based on the selected shape type and parameters
func create_polygon_shape() -> PackedVector2Array:
	match polygon_shape:
		Constants.PolygonShape.Circular:
			return PolygonLib.createCirclePolygon(cir_radius, cir_smoothing)
		Constants.PolygonShape.Rectangular:
			return PolygonLib.createRectanglePolygon(rectangle_size, rectangle_local_center)
		Constants.PolygonShape.Beam:
			return PolygonLib.createBeamPolygon(beam_dir, beam_distance, beam_start_width, beam_end_width, beam_start_point_local)
		Constants.PolygonShape.SuperEllipse:
			return PolygonLib.createSuperEllipsePolygon(s_p_number, s_a, s_b, e_n, s_start_angle_deg, s_max_angle_deg)
		Constants.PolygonShape.SuperShape:
			return PolygonLib.createSupershape2DPolygon(s_p_number, s_a, s_b, _rng.randf_range(min_m, m), _rng.randf_range(min_n1, n1), _rng.randf_range(min_n2, n2), _rng.randf_range(min_n3, n3), s_start_angle_deg, s_max_angle_deg)
		_:
			return PackedVector2Array([])

func reset_health() -> void:
	health.set_current_health(health.get_max_health())

func _on_zero_health() -> void:
	AudioManager.create_2d_audio_at_location(global_position, sound_effect_on_destroy.sound_type, sound_effect_on_destroy.destination_audio_bus)
	destroyed = true

func _apply_random_texture_properties() -> void:
	if randomize_texture_properties and is_instance_valid(poly_texture):
		var rand_scale : float = _rng.randf_range(0.25, 0.75)
		var t_size = poly_texture.get_size() / rand_scale
		var offset_range = t_size.x * 0.25
		_polygon2d.texture_offset = (t_size / 2) + Vector2(_rng.randf_range(-offset_range, offset_range), _rng.randf_range(-offset_range, offset_range))
		_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
		_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)

#region Getters and Setters

func set_initial_health(initial_health: float) -> void:
	health.set_max_health(initial_health)

## Sets up the fracturable body with given parameters
## [param initial_health] Starting health value
## [param shape_info] Dictionary containing shape information
## [param texture_info] Dictionary containing texture properties
## [param sound_details] Sound effect details for hit reactions
func set_fracture_body(initial_health: float, shape_info: Dictionary, texture_info: Dictionary, sound_details: SoundEffectDetails) -> void:
	# await GameManager.get_tree().process_frame
	
	set_texture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))
	set_hit_sound_effect(sound_details)
	set_initial_health(initial_health)

## Sets up the fracturable body with given parameters
## [param initial_health] Starting health value
## [param texture] Texture to apply to the body
## [param sound_details] Sound effect details for hit reactions
func setFractureBody(initial_health: float, texture: Texture2D, sound_details: SoundEffectDetails, normal_texture: Texture2D = null) -> void:
	await GameManager.get_tree().process_frame
	
	set_texture_with_texture(texture, normal_texture)
	set_hit_sound_effect(sound_details)
	set_initial_health(initial_health)

func set_texture_with_texture(new_texture: Texture2D, normal_texture: Texture2D = null) -> void:
	if normal_texture != null:
		_polygon2d.texture = CanvasTexture.new()
		_polygon2d.texture.diffuse_texture = new_texture
		_polygon2d.texture.normal_texture = normal_texture
	else:
		_polygon2d.texture = new_texture

func set_hit_sound_effect(sound: SoundEffectDetails, save_it: bool = false) -> void:
	if save_it:
		hit_sound_effect = sound
		_hit_sound_component.set_sound(hit_sound_effect)
	else:
		_hit_sound_component.set_sound(sound)

func set_polygon(poly : PackedVector2Array) -> void:
	setPolygon(poly)

func set_texture(texture_info: Dictionary) -> void:
	setTexture(texture_info)

func setPolygon(poly : PackedVector2Array) -> void:
	_polygon2d.set_polygon(poly)
	_col_polygon2d.set_polygon(poly)
	if !poly.is_empty():
		poly.append(poly[0])
	
	_line2d.points = poly
	light_occluder_2d.occluder.polygon = poly

func setTexture(texture_info : Dictionary) -> void:
	_polygon2d.texture = texture_info.texture
	_polygon2d.texture_scale = texture_info.scale
	_polygon2d.texture_offset = texture_info.offset
	_polygon2d.texture_rotation = texture_info.rot

func getPolygon() -> PackedVector2Array:
	return _polygon2d.get_polygon()

func getTextureInfo() -> Dictionary:
	var normal_texture: Texture2D
	if _polygon2d.texture is CanvasTexture:
		normal_texture = _polygon2d.texture.normal_texture
	else:
		normal_texture = null
	return {"texture" : _polygon2d.texture, "normal_texture": normal_texture, "rot" : _polygon2d.texture_rotation, "offset" : _polygon2d.texture_offset, "scale" : _polygon2d.texture_scale}

func get_texture_info() -> Dictionary:
	return getTextureInfo()

func getGlobalRotPolygon() -> float:
	return _polygon2d.global_rotation

func get_global_rotation_polygon() -> float:
	return getGlobalRotPolygon()

func get_polygon() -> PackedVector2Array:
	return getPolygon()

func get_sound_component() -> SoundEffectComponent:
	return _hit_sound_component

## Returns a Rect2 representing the smallest square that contains the entire polygon
func get_bounding_square() -> Rect2:
	# Get polygon points from shape
	var points = getPolygon()
	
	# Initialize bounds with first point
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y
	
	# Find min/max coordinates
	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)
	
	# Calculate dimensions
	var width = max_x - min_x
	var height = max_y - min_y
	var size = max(width, height)
	
	# Create square centered on polygon
	var center = Vector2((min_x + max_x) / 2, (min_y + max_y) / 2)
	var top_left = center - Vector2(size/2, size/2)

	return Rect2(top_left, Vector2(size, size))

## Returns the axis aligned bounding rectangle for the polygon
func get_bounding_rect() -> Rect2:
	var points = getPolygon()
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y

	for point in points:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

#endregion

## Applies damage to the fracturable body
## [param damage] Amount of damage to apply
## [param instakill] If true, immediately destroys the body
## Returns true if the body is destroyed, false otherwise
func take_damage(damage: float, instakill: bool = false) -> bool:
	if instakill:
		health.take_damage(1.79769e308)
		_hit_sound_component.set_and_play_sound(sound_effect_on_destroy)
		return true
	
	health.take_damage(damage)
	if health.get_current_health() <= 0.0:
		_hit_sound_component.set_and_play_sound(sound_effect_on_destroy)
		return true
	
	_hit_sound_component.set_and_play_sound(hit_sound_effect)
	GameManager.player.get_health_node().take_damage(pow(2.0, GameManager.get_level_index()))
	return false
