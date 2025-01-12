class_name Quadrant extends FracturableStaticBody2D


var is_carved: bool = false
var can_carve: bool = false

var current_health: float= 0.0
var initial_health: float = 0.0

var default_quadrant_polygon: PackedVector2Array = []
var builder_args: QuadrantBuilderArgs
var damage_to_deal: float = 25.0


func _ready() -> void:
	_rng.randomize()
	builder_args = GameManager.builder_args
	if placed_in_level:
		var poly = create_polygon_shape()
		
		setPolygon(poly)
		
		_polygon2d.texture = poly_texture
		
		if randomize_texture_properties and is_instance_valid(poly_texture):
			var rand_scale : float = _rng.randf_range(0.25, 0.75)
			var t_size = poly_texture.get_size() / rand_scale
			var offset_range = t_size.x * 0.25
			_polygon2d.texture_offset = (t_size / 2) + Vector2(_rng.randf_range(-offset_range, offset_range), _rng.randf_range(-offset_range, offset_range))
			_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
			_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)

func create_polygon_shape() -> PackedVector2Array:
	return PolygonLib.createRectanglePolygon(rectangle_size, rectangle_local_center)

func init_health(_health: float = -1) -> void:
	if _health != -1:
		initial_health = _health
		initial_health += increase_health(_health)
		current_health = initial_health
	else:
		initial_health = 5000.0
		current_health = initial_health

func increase_health(_health: float) -> float:
	return _health * pow(5.0, GameManager.current_level_index)

"""
Inflicts damage to the polygon, if the polygon's health is zero, then the polygon can
be carved returning true, false otherwise
"""
func take_damage(damage_taken: float, instakill: bool = false) -> bool:
	if instakill:
		current_health = 0.0
	else:
		current_health = max(0, current_health - damage_taken)  # Clamp the value to a minimum of 0
	
	if current_health <= 0.0 && is_carved == false:
		can_carve = true
		is_carved = true
		return true
	
	GameManager.emit_signal("quadrant_hitted", damage_to_deal)
	can_carve = false
	is_carved = false
	return false

func issue_fiat_money() -> void:
	BitcoinWallet.add_fiat(get_fiat_subsidy())

func get_fiat_subsidy() -> float:
	var rand = randf_range(1000.0, 5000.0)
	return rand * pow(10, builder_args.drop_rate_multiplier)
