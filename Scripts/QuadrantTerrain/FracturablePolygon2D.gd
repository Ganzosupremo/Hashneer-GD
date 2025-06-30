## ## A class that represents a destructible entity in 2D space.
## It can be created with different shapes and supports texture customization,
## health management, and collision detection.
class_name FracturablePolygon2D extends RigidBody2D


signal entity_damaged(damage_amount: float, impact_point: Vector2)
signal entity_healed(amount: float)
signal entity_restored(new_polygon: PackedVector2Array)


@onready var _polygon2d: Polygon2D = $Polygon2D
@onready var _line2d: Line2D = $Polygon2D/Line2D
@onready var _col_polygon2d: CollisionPolygon2D = $CollisionPolygon2D
@onready var _rng: RandomNumberGenerator= RandomNumberGenerator.new()
@onready var health: FractureBodyHealthComponent = %Health
@onready var light_occluder_2d: LightOccluder2D = $LightOccluder2D
@onready var _poly_fracture: PolygonFracture = PolygonFracture.new()

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

#region Healing & Regeneration
@export_group("Healing & Regeneration")
## If true, this entity can regenerate health over time
@export var can_regenerate: bool = false
## When health percentage is above this threshold, it's considered fully healed
@export var heal_threshold: float = 0.8
## How much health to restore on each regeneration tick
@export var regeneration_amount: float = 10.0
## Range of time between regeneration ticks (min, max)
@export var regeneration_interval_range: Vector2 = Vector2(1.0, 3.0)
## How long to wait after taking damage before regeneration begins
@export var regeneration_delay: float = 3.0
## Rate at which to continuously heal when regenerating
@export var continuous_regeneration_rate: float = 0.0
## If true, entity will store polygon history for smoother restoration
@export var use_polygon_history: bool = true
#endregion

#endregion

# Stored properties for healing/regeneration
var original_polygon: PackedVector2Array # Original/full health polygon
var initial_polygon_area: float = 0.0 # Area of the original polygon
var polygon_restorer: PolygonRestorer # Stores polygon history for restoration
var destroyed: bool = false # Whether this entity is considered destroyed
var regen_timer: float = 0.0 # Timer for regeneration delay
var total_healing_amount: float = 0.0 # Tracks healing to apply in the current frame
var regeneration_active: bool = false # Whether regeneration is currently active

# -- REGENERATION TIMER --
var _regeneration_timer: Timer = null

func _ready() -> void:
	# Connect health component signals
	health.zero_health.connect(_on_zero_health)
	
	_rng.randomize()
	
	# Initialize polygon shape
	if placed_in_level:
		var poly = _create_polygon_shape()
		setPolygon(poly)
		
	# Initialize polygon history if enabled
	if use_polygon_history:
		polygon_restorer = PolygonRestorer.new()
		# Store original polygon for reference
		original_polygon = _polygon2d.polygon.duplicate()
		initial_polygon_area = PolygonLib.getPolygonArea(original_polygon)
		
		# Add to restorer if available
		if polygon_restorer:
			polygon_restorer.addShape(original_polygon, initial_polygon_area)
	else:
		# Store original shape even without history
		original_polygon = _polygon2d.polygon.duplicate()
		initial_polygon_area = PolygonLib.getPolygonArea(original_polygon)
	
	# Set up regeneration timer if enabled
	if can_regenerate and regeneration_interval_range != Vector2.ZERO:
		_regeneration_timer = Timer.new()
		_regeneration_timer.one_shot = true
		add_child(_regeneration_timer)
		_regeneration_timer.timeout.connect(_on_regeneration_timer_timeout)
	
	_randomize_texture_properties()

func _process(delta: float) -> void:
	# Process regeneration logic
	if can_regenerate:
		# Check regeneration delay timer
		if regen_timer > 0:
			regen_timer -= delta
			
		# Apply continuous regeneration if enabled and active
		if continuous_regeneration_rate > 0.0 and regeneration_active:
			if health.get_current_health() < health.get_max_health():
				health.heal(continuous_regeneration_rate * delta)
	
	# Process pending healing (for visual restoration)
	if total_healing_amount > 0.0:
		# Call restore at the end of this frame
		call_deferred("restore")

#region Damage & Healing Functions
## Apply damage to this entity with fracture effects
## [param damage_amount] The amount of damage to apply
## [param impact_point] The global position where damage occurred
## [param cut_extents_min_max] The min/max size for the cut shape (default: Vector2(30, 70))
## [param min_area_percent] Minimum percentage of area to keep (default: 0.15)
func damage_with_fracture(damage_amount: Vector2, impact_point: Vector2, 
						 cut_extents_min_max: Vector2 = Vector2(30, 70),
						 min_area_percent: float = 0.15) -> Dictionary:
	if destroyed:
		return {"percent_cut": 0.0, "dead": true}
	
	# Generate cut shape
	var cut_shape: PackedVector2Array = _poly_fracture.generateRandomPolygon(
		damage_amount, cut_extents_min_max, Vector2.ZERO
	)
	
	var _cut_shape_area: float = PolygonLib.getPolygonArea(cut_shape)
	
	# Convert global impact point to local
	var impact_point_local = to_local(impact_point)
	
	# Calculate minimum area to keep
	var min_area_to_keep = initial_polygon_area * min_area_percent
	
	# Perform the fracture
	var fracture_info: Dictionary = _poly_fracture.cutFracture(
		_polygon2d.polygon,
		cut_shape,
		global_transform,
		Transform2D(0.0, impact_point_local),
		min_area_to_keep,
		10.0,  # Min shard area
		5.0,   # Min site distance
		1      # Max fractures
	)
	
	var current_area = PolygonLib.getPolygonArea(_polygon2d.polygon)
	var percent_cut: float = 0.0
	
	# Handle fracture results
	if not fracture_info or not fracture_info.has("shapes") or fracture_info.shapes.is_empty():
		# No valid shapes returned, consider entity destroyed
		health.take_damage(health.get_current_health())
		destroyed = true
		percent_cut = 1.0
	else:
		# Find the largest remaining piece
		var largest_area = -1.0
		var main_shape = {}
		
		for shape in fracture_info.shapes:
			if shape.area > largest_area:
				largest_area = shape.area
				main_shape = shape
		
		if not main_shape.is_empty():
			# Store this shape for restoration if using history
			if polygon_restorer:
				polygon_restorer.addShape(main_shape.shape, main_shape.area)
			
			# Update visuals with the new shape
			setPolygon(main_shape.shape)
			
			# Calculate percentage cut
			percent_cut = 1.0 - (main_shape.area / current_area)
			
			# Apply damage based on area lost
			var damage_to_health = health.get_max_health() * percent_cut
			health.take_damage(damage_to_health)
			
			# Reset regeneration timer
			regen_timer = regeneration_delay
	
	# Emit signal for damage
	entity_damaged.emit(damage_amount.length(), impact_point)
	
	return {"percent_cut": percent_cut, "dead": health.is_dead()}

## Apply healing to the entity and manage related visual effects
## [param heal_amount] The amount of health to restore
func heal(heal_amount: float) -> void:
	if destroyed or health.get_current_health() >= health.get_max_health():
		return
	
	# Calculate health percentage after healing
	var would_be_health = health.get_current_health() + heal_amount
	var health_percent = would_be_health / health.get_max_health()
	
	# Fully healed case
	if health_percent >= heal_threshold:
		# Restore to original shape
		setPolygon(original_polygon)
		health.set_current_health(health.get_max_health())
		entity_restored.emit(original_polygon)
		
		# Stop regeneration since we're fully healed
		if regeneration_active:
			regeneration_active = false
			if _regeneration_timer:
				_regeneration_timer.stop()
	else:
		# Partial healing
		if total_healing_amount == 0.0:
			# First healing in this frame
			call_deferred("restore")
		
		# Add to healing queue
		total_healing_amount += heal_amount
		health.heal(heal_amount)
	
	# Emit signal for healing
	entity_healed.emit(heal_amount)

## Restores the entity's polygon based on healing amount
func restore() -> void:
	if total_healing_amount <= 0.0 or destroyed:
		return
	
	var poly: PackedVector2Array
	var area: float = 0.0
	
	# Use polygon history if available
	if use_polygon_history and polygon_restorer and not polygon_restorer.isEmpty():
		var shape_entry = polygon_restorer.popLast()
		poly = shape_entry.shape
		area = shape_entry.area
	else:
		# Calculate interpolated shape between current and original
		poly = PolygonLib.restorePolygon(_polygon2d.polygon, original_polygon, total_healing_amount)
		area = PolygonLib.getPolygonArea(poly)
	
	# Apply the restored shape
	setPolygon(poly)
	
	# Reset the healing amount
	total_healing_amount = 0.0
	
	# Emit signal for restoration
	entity_restored.emit(poly)

## Start the regeneration process
func start_regeneration() -> void:
	if not can_regenerate or destroyed or regeneration_active:
		return
	
	if _regeneration_timer:
		var rand_time = randf_range(regeneration_interval_range.x, regeneration_interval_range.y)
		_regeneration_timer.start(rand_time)
		regeneration_active = true

## Stop the regeneration process
func stop_regeneration() -> void:
	regeneration_active = false
	if _regeneration_timer:
		_regeneration_timer.stop()

## Reset the entity to its original state
func reset_entity() -> void:
	if destroyed:
		destroyed = false
	
	# Restore original polygon
	if not original_polygon.is_empty():
		setPolygon(original_polygon)
	else:
		# Regenerate polygon if original wasn't saved
		var poly = _create_polygon_shape()
		setPolygon(poly)
		original_polygon = poly.duplicate()
		initial_polygon_area = PolygonLib.getPolygonArea(poly)
	
	# Reset health
	health.set_current_health(health.get_max_health())
	
	# Reset regeneration state
	regeneration_active = false
	regen_timer = 0.0
	total_healing_amount = 0.0
	
	# Clear polygon history
	if use_polygon_history and polygon_restorer:
		polygon_restorer.clear()
		polygon_restorer.addShape(original_polygon, initial_polygon_area)
	
	# Make sure entity is visible
	if _polygon2d:
		_polygon2d.visible = true
	if _line2d:
		_line2d.visible = true

## Applies damage to the fracturable body
## [param damage] Amount of damage to apply
## [param instakill] If true, immediately destroys the body
## Returns true if the body is destroyed, false otherwise
func take_damage(damage: float, instakill: bool = false) -> bool:
	if instakill:
		health.take_damage(1.79769e308)
		return true
	
	health.take_damage(damage)
	if health.get_current_health() <= 0.0:
		return true
	
	GameManager.player.get_health_node().take_damage(pow(2.0, GameManager.get_level_index()))
	return false
#endregion

## Recreates the polygon shape with current parameters
func recreate_polygon_shape() -> void:
	var poly = _create_polygon_shape()
	setPolygon(poly)
	_randomize_texture_properties()

func _randomize_texture_properties() -> void:
	if randomize_texture_properties and is_instance_valid(poly_texture):
		var rand_scale : float = _rng.randf_range(0.25, 0.75)
		var t_size = poly_texture.get_size() / rand_scale
		var offset_range = t_size.x * 0.25
		_polygon2d.texture_offset = (t_size / 2) + Vector2(_rng.randf_range(-offset_range, offset_range), _rng.randf_range(-offset_range, offset_range))
		_polygon2d.texture_scale = Vector2(rand_scale, rand_scale)
		_polygon2d.texture_rotation = _rng.randf_range(0.0, PI * 2.0)

## Creates a polygon shape based on the selected shape type and parameters
func _create_polygon_shape() -> PackedVector2Array:
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

#region Signals
func _on_zero_health() -> void:
	AudioManager.create_2d_audio_at_location(global_position, sound_effect_on_destroy.sound_type, sound_effect_on_destroy.destination_audio_bus)
	destroyed = true

## Called when regeneration timer expires
func _on_regeneration_timer_timeout() -> void:
	if destroyed or health.get_current_health() >= health.get_max_health():
		regeneration_active = false
		return
	
	# Apply regeneration amount
	heal(regeneration_amount)
	
	# Re-schedule next regeneration tick if not fully healed
	if health.get_current_health() < health.get_max_health():
		start_regeneration()
#endregion

#region Getters and Setters
func set_initial_health(initial_health: float) -> void:
	health.set_max_health(initial_health)

## Sets up the fracturable body with given parameters
## [param initial_health] Starting health value
## [param shape_info] Dictionary containing shape information
## [param texture_info] Dictionary containing texture properties
## [param sound_details] Sound effect details for hit reactions
func set_fracture_body(initial_health: float, shape_info: Dictionary, texture_info: Dictionary) -> void:
	# await GameManager.get_tree().process_frame
	
	set_texture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))
	set_initial_health(initial_health)

## Sets up the fracturable body with given parameters
## [param initial_health] Starting health value
## [param texture] Texture to apply to the body
## [param sound_details] Sound effect details for hit reactions
func setFractureBody(initial_health: float, texture: Texture2D, normal_texture: Texture2D = null) -> void:
	await GameManager.get_tree().process_frame
	
	set_texture_with_texture(texture, normal_texture)
	set_initial_health(initial_health)

func set_texture_with_texture(new_texture: Texture2D, normal_texture: Texture2D = null) -> void:
	if normal_texture != null:
		_polygon2d.texture = CanvasTexture.new()
		_polygon2d.texture.diffuse_texture = new_texture
		_polygon2d.texture.normal_texture = normal_texture
	else:
		_polygon2d.texture = new_texture


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
#endregion
