class_name BlockCore extends FracturableStaticBody2D

signal onBlockDestroyed()

@onready var _shatter_visualizer: Polygon2D = $ShatterVisualizer
@onready var _shatter_line_2d: Line2D = $ShatterVisualizer/ShatterLine2D
@onready var _slowdown_timer: Timer = $SlowDownTimer
@onready var _block_core_particles: GPUParticles2D = $BlockCoreParticles


var _poly_fracture: PolygonFracture
var _cur_fracture_color: Color
var level_index: int = 0
var _hit_tween: Tween = null

func _ready() -> void:
	_slowdown_timer.timeout.connect(_on_slow_down_timer_timeout)
	GameManager._current_block_core = self
	_poly_fracture = PolygonFracture.new()
	_rng.randomize()
	_block_core_particles.emitting = false
	_block_core_particles.one_shot = true

	if placed_in_level:
		var poly: PackedVector2Array = create_polygon_shape()
		
		setPolygon(poly)
		
		set_texture({"texture": poly_texture, 
		"normal_texture": null, 
		"rot": _polygon2d.texture_rotation, 
		"offset": _polygon2d.texture_offset, 
		"scale": _polygon2d.texture_scale})
		_set_random_texture_properties()


func _set_random_texture_properties() -> void:
	if randomize_texture_properties and is_instance_valid(poly_texture):
		var rand_scale: float = _rng.randf_range(0.25, 0.75)
		var t_size = poly_texture.get_size() / rand_scale
		var offset_range = t_size.x * 0.25
		_polygon2d.texture_offset = (t_size / 2) + Vector2(_rng.randf_range(-offset_range, offset_range), _rng.randf_range(-offset_range, offset_range))
		_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
		_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)


## This method checks if the block core's health 
## has been reduced to zero before fracturing the core.
func fracture(cuts: int, min_area: float, bullet_damage: float, fracture_color: Color = Color.WHITE_SMOKE, instakill: bool = false, miner: String = "Player") -> void:
	if take_damage(bullet_damage, instakill):
		_fracture_all(self, cuts, min_area, fracture_color, miner)
	else:
		_make_cut_in_polygon(_shatter_visualizer, fracture_color)

func take_damage(damage: float, instakill: bool = false) -> bool:
	if instakill:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_DESTROYED, AudioManager.DestinationAudioBus.SFX)
		health.take_damage(1.79769e308)
		
		return true
	
	health.take_damage(damage)
	if health.get_current_health() <= 0.0:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_DESTROYED, AudioManager.DestinationAudioBus.SFX)
		return true
	
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_HIT, AudioManager.DestinationAudioBus.SFX)
	GameManager.get_player().get_health_node().take_damage(pow(2.0, GameManager.get_level_index()))
	return false

# Store the cut info for progressive cuts
var cut_info_storage: Array = []

## Just make a visual cut in the Polygon2D 
##but actually don't fracture the polygon 
func _make_cut_in_polygon(source: Node2D, fracture_color: Color) -> void:
	if cut_info_storage.size() == 0:
		var source_polygon: PackedVector2Array = source.get_polygon()
		var source_transform: Transform2D = source.get_global_transform()
		cut_info_storage = _poly_fracture.fractureSimple(source_polygon, source_transform, 2, 5000.0)
	
	if cut_info_storage.size() > 0:
		_update_polygon_visual(source, cut_info_storage.pop_back(), fracture_color)
		_play_hit_effect()

func _play_hit_effect() -> void:
	if _hit_tween:
		_hit_tween.kill()
	_block_core_particles.emitting = true
	_block_core_particles.restart()
	_hit_tween = create_tween()
	_hit_tween.tween_property(_shatter_visualizer, "modulate:a", 0.0, 0.3)
	_hit_tween.tween_property(_shatter_line_2d, "modulate:a", 0.0, 0.3)
	_hit_tween.tween_callback(Callable(self, "_reset_shatter_alpha"))

func _reset_shatter_alpha() -> void:
	_shatter_visualizer.modulate.a = 1.0
	_shatter_line_2d.modulate.a = 1.0

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
		var color: Color = source.self_modulate
		color.s = fracture_color.s
		color.v = fracture_color.v
		color.h = _rng.randf()
		color.a = 100.0
		_cur_fracture_color = color
		_shatter_visualizer.self_modulate = _cur_fracture_color

func _fracture_all(other_body: FracturableStaticBody2D, cuts: int, min_area: float, fracture_color: Color = Color.HONEYDEW, _miner: String = "Player") -> void:
	_cur_fracture_color = fracture_color

	if !destroyed:
		destroyed = true
		onBlockDestroyed.emit()

		_slowdown_timer.start(1.0)
		_block_core_particles.emitting = false
		Engine.time_scale = 0.21
		
		GameManager._player_camera.shake_with_preset(Constants.ShakeMagnitude.Large)
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.EXPLOSION, global_transform)
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.DEBRIS, global_transform)
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.SCREEN_FLASH, Transform2D.IDENTITY, null, 0.15)

		_destroy_block_core(other_body, cuts, min_area)
		random_drops.spawn_drops(1)

func _destroy_block_core(source, cuts: int, min_area: float) -> void:
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
	var body_instance = get_parent().pool_fracture_bodies.getInstance()
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
	var level_id: int = GameManager.get_current_level()
	var block: BitcoinBlock = null
	if BitcoinNetwork.is_level_mined(level_id):
			block = BitcoinNetwork.get_block_by_id(level_id)

	BitcoinNetwork.mine_block(miner, block)

func _on_slow_down_timer_timeout() -> void:
	Engine.time_scale = 1.0
	hide()
	
	var arr: PackedVector2Array = PackedVector2Array([])
	setPolygon(arr)

func getTextureInfo() -> Dictionary:
	return {"texture" : _polygon2d.texture, "rot" : _polygon2d.texture_rotation, "offset" : _polygon2d.texture_offset, "scale" : _polygon2d.texture_scale}

func setPolygon(poly: PackedVector2Array):
	super.setPolygon(poly)
	_line2d.points = poly
	_shatter_visualizer.polygon = poly
	_shatter_line_2d.points = poly
