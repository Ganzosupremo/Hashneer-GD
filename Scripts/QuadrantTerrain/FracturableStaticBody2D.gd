class_name FracturableStaticBody2D extends StaticBody2D

@onready var _polygon2d: Polygon2D = $Polygon2D
@onready var _line2d: Line2D = $Polygon2D/Line2D
@onready var _col_polygon2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var _rng: RandomNumberGenerator= RandomNumberGenerator.new()
@onready var health: HealthComponent = %Health
@onready var _hit_sound_component: SoundEffectComponent = %HitSoundComponent

@export_group("General")
@export var placed_in_level: bool = false
@export var randomize_texture_properties: bool = true
@export var poly_texture: Texture2D
@export var hit_sound_effect: SoundEffectDetails

enum PolygonShape { Circular, Rectangular, Beam, SuperEllipse, SuperShape}
@export_group("Shape")
@export var polygon_shape: PolygonShape

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

func _ready() -> void:
	#if hit_sound_effect != null:
		#_hit_sound_component.set_sound(hit_sound_effect)
	
	_rng.randomize()
	if placed_in_level:
		var poly = create_polygon_shape()
		
		setPolygon(poly)
		#_polygon2d.texture = poly_texture
		
		
		if randomize_texture_properties and is_instance_valid(poly_texture):
			var rand_scale : float = _rng.randf_range(0.25, 0.75)
			var t_size = poly_texture.get_size() / rand_scale
			var offset_range = t_size.x * 0.25
			_polygon2d.texture_offset = (t_size / 2) + Vector2(_rng.randf_range(-offset_range, offset_range), _rng.randf_range(-offset_range, offset_range))
			_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
			_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)


func recreate_polygon_shape() -> void:
	var poly = create_polygon_shape()
	setPolygon(poly)

	if randomize_texture_properties and is_instance_valid(poly_texture):
		var rand_scale : float = _rng.randf_range(0.25, 0.75)
		var t_size = poly_texture.get_size() / rand_scale
		var offset_range = t_size.x * 0.25
		_polygon2d.texture_offset = (t_size / 2) + Vector2(_rng.randf_range(-offset_range, offset_range), _rng.randf_range(-offset_range, offset_range))
		_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
		_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)

func create_polygon_shape() -> PackedVector2Array:
	match polygon_shape:
		PolygonShape.Circular:
			return PolygonLib.createCirclePolygon(cir_radius, cir_smoothing)
		PolygonShape.Rectangular:
			return PolygonLib.createRectanglePolygon(rectangle_size, rectangle_local_center)
		PolygonShape.Beam:
			return PolygonLib.createBeamPolygon(beam_dir, beam_distance, beam_start_width, beam_end_width, beam_start_point_local)
		PolygonShape.SuperEllipse:
			return PolygonLib.createSuperEllipsePolygon(s_p_number, s_a, s_b, e_n, s_start_angle_deg, s_max_angle_deg)
		PolygonShape.SuperShape:
			return PolygonLib.createSupershape2DPolygon(s_p_number, s_a, s_b, _rng.randf_range(min_m, m), _rng.randf_range(min_n1, n1), _rng.randf_range(min_n2, n2), _rng.randf_range(min_n3, n3), s_start_angle_deg, s_max_angle_deg)
		_:
			return PackedVector2Array([])

func play_sound_on_hit() -> void:
	_hit_sound_component.play_sound()

func shake_camera_on_collision(magnitude: Constants.ShakeMagnitude = Constants.ShakeMagnitude.Small):
	GameManager.player.get_player_camera().shake_with_preset(magnitude)


# ______________________Geters and Setters_______________________________________

func set_initial_health(initial_health: float) -> void:
	health.set_max_health(initial_health)

func set_fracture_body(initial_healt: float, fracture_texture: Texture2D, sound_details: SoundEffectDetails) -> void:
	await GameManager.get_tree().process_frame
	
	set_texture_with_texture(fracture_texture)
	set_hit_sound_effect(sound_details)
	set_initial_health(initial_healt)

func set_texture_with_texture(new_texture: Texture2D) -> void:
	_polygon2d.texture = new_texture

func set_hit_sound_effect(sound: SoundEffectDetails, save_it: bool = true) -> void:
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
	poly.append(poly[0])
	_line2d.points = poly

func setTexture(texture_info : Dictionary) -> void:
	_polygon2d.texture = texture_info.texture
	_polygon2d.texture_scale = texture_info.scale
	_polygon2d.texture_offset = texture_info.offset
	_polygon2d.texture_rotation = texture_info.rot

func getPolygon() -> PackedVector2Array:
	return _polygon2d.get_polygon()

func getTextureInfo() -> Dictionary:
	return {"texture" : _polygon2d.texture, "rot" : _polygon2d.texture_rotation, "offset" : _polygon2d.texture_offset, "scale" : _polygon2d.texture_scale}

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


"""
Deals damage to this quadrant, returns true if it's health is zero,
false otherwise
"""
func take_damage(damage: float, instakill: bool = false) -> bool:
	if instakill:
		health.take_damage(1.79769e308)
		return true
	health.take_damage(damage)
	if health.get_current_health() <= 0.0:
		return true
	
	GameManager.player.get_health_node().take_damage(1.0)
	return false
