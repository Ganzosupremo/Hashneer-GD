class_name BlockCore extends FracturableStaticBody2D

#signal block_mined()

@onready var _shatter_visualizer: Polygon2D = $ShatterVisualizer
@onready var _shatter_line_2d: Line2D = $ShatterVisualizer/ShatterLine2D
@onready var _slowdown_timer: Timer = $SlowDownTimer

var _poly_fracture: PolygonFracture
var _cur_fracture_color: Color
var level_index: int = 0
var core_destroyed: bool = false

func _ready() -> void:
	GameManager.current_block_core = self
	_poly_fracture = PolygonFracture.new()
	_rng.randomize()
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

"""
This method checks if the block core's health 
has been reduced to zero before fracturing the core.
"""
func fracture_all(other_body, cuts: float, min_area: float, bullet_damage: float, fracture_color: Color = Color.HONEYDEW, instakill: bool = false, miner: String = "Player") -> void:
	if take_damage(bullet_damage, instakill):
		_fracture_all(other_body, cuts, min_area, fracture_color, miner)
	else:
		_make_cut_in_polygon(_shatter_visualizer, fracture_color)

# Store the cut info for progressive cuts
var cut_info_storage: Array = []
"""
Just make a visual cut in the Polygon2D 
but actually don't fracture the polygon 
"""
func _make_cut_in_polygon(source: Node2D, fracture_color: Color) -> void:
	if cut_info_storage.size() == 0:
		var source_polygon: PackedVector2Array = source.get_polygon()
		var source_transform: Transform2D = source.get_global_transform()
		cut_info_storage = _poly_fracture.fractureSimple(source_polygon, source_transform, 2, 5000.0)
	
	if cut_info_storage.size() > 0:
		_update_polygon_visual(source, cut_info_storage.pop_back(), fracture_color)

func _update_polygon_visual(source: Node2D, cut_info: Dictionary, fracture_color: Color):
	# Update the Polygon2D's polygon with the new shape's vertices
	if cut_info.has("shape"):
		var new_shape = PackedVector2Array()
		for vertex in cut_info["shape"]:
			new_shape.append(Vector2(vertex[0], vertex[1]))

		# Apply the new vertices to the Polygon2D
		_shatter_visualizer.set_polygon(new_shape)
		_shatter_line_2d.points = new_shape
		
		# Change color of the polygon
		var color := Color.WHITE
		color.s = fracture_color.s
		color.v = fracture_color.v
		color.h = _rng.randf()
		color.a = 100.0
		_cur_fracture_color = color
		_shatter_visualizer.self_modulate = _cur_fracture_color

func _fracture_all(other_body, cuts: float, min_area: float, fracture_color: Color = Color.HONEYDEW, miner: String = "Player") -> void:
	_cur_fracture_color = fracture_color
	_slowdown_timer.start(0.21)
	Engine.time_scale = 0.21
	if !core_destroyed:
		core_destroyed = true
		_destroy_block_core(other_body, cuts, min_area)
		_mine_block(miner)
		GameManager.level_completed()
		#emit_signal("block_mined")

func _destroy_block_core(source, cuts: float, min_area: float) -> void:
	visible = false
	_shatter_visualizer.visible = false
	_shatter_line_2d.visible = false
	var source_polygon: PackedVector2Array = source.get_polygon()

	var source_transform: Transform2D = source.get_global_transform()
	var cut_fracture_info: Array = _poly_fracture.fractureDelaunay(source_polygon, source_transform, cuts, min_area)
	
	for info_dic in cut_fracture_info:
		var texture_info: Dictionary = getTextureInfo()
		_spawn_fracture_body(info_dic, texture_info)

func _spawn_fracture_body(fracture_info: Dictionary, texture_info: Dictionary) -> void:
	var body_instance = get_parent()._pool_fracture_bodies.getInstance()
	if not body_instance: 
		return
	
	body_instance.spawn(fracture_info.spawn_pos)
	body_instance.global_rotation = fracture_info.spawn_rot
	if body_instance.has_method("setPolygon"):
		var s : Vector2 = fracture_info.source_global_trans.get_scale()
		body_instance.setPolygon(fracture_info.centered_shape, s)


	body_instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (fracture_info.spawn_pos - fracture_info.source_global_trans.get_origin()).normalized()
	body_instance.linear_velocity = dir * _rng.randf_range(200, 400)
	body_instance.angular_velocity = _rng.randf_range(-1, 1)

	body_instance.setTexture(PolygonLib.setTextureOffset(texture_info, fracture_info.centroid))

func _mine_block(miner: String = "Player") -> void:
	BitcoinNetwork.mine_block(miner)

func _on_slow_down_timer_timeout() -> void:
	Engine.time_scale = 1.0
	queue_free()

func setPolygon(poly: PackedVector2Array):
	super.setPolygon(poly)
	_shatter_visualizer.polygon = poly
	_shatter_line_2d.points = poly
