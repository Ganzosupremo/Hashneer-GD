class_name FracturableStaticBody2D extends StaticBody2D

@onready var _polygon2d := $Polygon2D
@onready var _line2d := $Polygon2D/Line2D
@onready var _col_polygon2d := $CollisionPolygon2D
@onready var _rng := RandomNumberGenerator.new()
@onready var health: HealthComponent = %Health
@onready var _hit_sound_component: SoundEffectComponent = %HitSoundComponent


@export var placed_in_level: bool = false
@export var randomize_texture_properties: bool = true
@export var poly_texture: Texture2D

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
@export var m : float = 0
@export var n1 : float = 0
@export var n2 : float = 0
@export var n3 : float = 0


var _hit_sound: SoundEffectDetails

func _ready() -> void:
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


func create_polygon_shape() -> PackedVector2Array:
	if polygon_shape == PolygonShape.Circular:
		return PolygonLib.createCirclePolygon(cir_radius, cir_smoothing)
	elif polygon_shape == PolygonShape.Rectangular:
		return PolygonLib.createRectanglePolygon(rectangle_size, rectangle_local_center)
	elif polygon_shape == PolygonShape.Beam:
		return PolygonLib.createBeamPolygon(beam_dir, beam_distance, beam_start_width, beam_end_width, beam_start_point_local)
	elif polygon_shape == PolygonShape.SuperEllipse:
		return PolygonLib.createSuperEllipsePolygon(s_p_number, s_a, s_b, e_n, s_start_angle_deg, s_max_angle_deg)
	elif polygon_shape == PolygonShape.SuperShape:
		return PolygonLib.createSupershape2DPolygon(s_p_number, s_a, s_b, m, n1, n2, n3, s_start_angle_deg, s_max_angle_deg)
	else: return PackedVector2Array([])


# Geters and Setters
func set_initial_health(initial_health: float) -> void:
	health.set_max_health(initial_health)

func set_fracture_body(initial_healt: float, fracture_texture: Texture2D, sound_details: SoundEffectDetails) -> void:
	await get_tree().physics_frame
	
	set_initial_health(initial_healt)
	set_texture_with_texture(fracture_texture)
	set_hit_sound_effect(sound_details)


func set_texture_with_texture(new_texture: Texture2D) -> void:
	_polygon2d.texture = new_texture


func set_hit_sound_effect(sound: SoundEffectDetails) -> void:
	_hit_sound = sound
	_hit_sound_component.set_sound(_hit_sound)


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

"""
Deals damage to this quadrant, returns true if it's health is zero,
false otherwise
"""
func take_damage(damage: float, instakill: bool = false) -> bool:
	if instakill:
		health.take_damage(1.79769e308)
		return true
	health.take_damage(damage)
	#_hit_sound_component.play_sound()
	
	if health.get_current_health() <= 0.0:
		return true
	
	GameManager.player.get_health_node().take_damage(1.0)
	return false
