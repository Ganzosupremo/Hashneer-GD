class_name ShieldComponent extends Area2D

signal shield_depleted()
signal shield_changed(ref: ShieldComponent, new_value: float)
signal fractured(ref: ShieldComponent, fracture_shard: Dictionary, new_mass: float, color: Color, fracture_force: float, p: float)

@export_category("Shield Settings")
@export var shield_visibility_scale: float = 1.2  ## Makes the shield visibly larger than its collision area
@export var max_shield: float = 100.0
@export var shield_radius: float = 80.0

@export_group("Fracture Settings")
## Min/Max extents for the random cutting polygon generation
@export var shield_fracture_cut_extents_min_max: Vector2 = Vector2(20, 50) 
## Min percentage of area to keep after fracture
@export var shield_min_area_percent: float = 0.1 
  
@export_group("Visual Effects")
@export var hit_effect_duration: float = 1.0

@export_group("Regeneration")
@export var can_regenerate: bool = true
@export var regeneration_delay: float = 3.0
@export var regeneration_amount: float = 10.0
@export var regeneration_rate: float = 0.5  # Time between regeneration ticks

# Internal components
@onready var _polygon2d: Polygon2D = $Polygon2D
@onready var _line2d: Line2D = $Polygon2D/Line2D
@onready var _collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _poly_fracture: PolygonFracture = PolygonFracture.new()

# Shield state
var current_shield: float = 0.0
var original_polygon: PackedVector2Array
var initial_polygon_area: float = 0.0
var destroyed: bool = false
var regen_timer: float = 0.0
var regeneration_active: bool = false
var _hit_effect_timer: float = 0.0
var _regeneration_timer: Timer

# Parent entity reference
var parent_entity: Node2D

func _ready() -> void:
	_rng.randomize()
		
	# Create circular shield polygon
	var polygon = PolygonLib.createCirclePolygon(shield_radius, 16)
	#var shield_area = PolygonLib.getPolygonArea(polygon)
	current_shield = max_shield
	_setup_shield_polygon(polygon, true)
	
	# Set up regeneration timer
	_regeneration_timer = Timer.new()
	_regeneration_timer.wait_time = regeneration_rate
	_regeneration_timer.one_shot = true
	_regeneration_timer.autostart = false
	add_child(_regeneration_timer)
	_regeneration_timer.timeout.connect(_on_regeneration_tick)
	_regeneration_timer.stop()
	
	if can_regenerate:
		_regeneration_timer.start()
	
	# Connect to parent entity
	parent_entity = get_parent()


func _setup_shield_polygon(polygon: PackedVector2Array, should_scale: bool = false) -> void:
	# Store original polygon
	original_polygon = polygon.duplicate()
	initial_polygon_area = PolygonLib.getPolygonArea(original_polygon)
	
	# Apply visual scaling
	var scaled_polygon: PackedVector2Array = PackedVector2Array()
	for point in polygon:
		if should_scale:
			scaled_polygon.append(point * shield_visibility_scale)
		else:
			scaled_polygon.append(point)

	# Set up visual components
	_polygon2d.polygon = scaled_polygon
	if !scaled_polygon.is_empty():
		var line_points = scaled_polygon.duplicate()
		line_points.append(line_points[0])  # Close the polygon
		_line2d.points = line_points
	
	# Set up collision (unscaled for accurate collision detection)
	_collision_polygon.set_deferred("polygon", polygon)

func _process(delta: float) -> void:
	# Handle shield-specific hit effect fade
	if _hit_effect_timer > 0:
		_hit_effect_timer -= delta * 2.0
		# Update visual effects based on _hit_effect_timer
		if _polygon2d.material and _polygon2d.material is ShaderMaterial:
			var shader_mat = _polygon2d.material as ShaderMaterial
			shader_mat.set_shader_parameter("hit_effect", _hit_effect_timer / hit_effect_duration)
	
	# Handle regeneration delay timer
	if can_regenerate and regen_timer > 0:
		regen_timer -= delta
		
	# Follow parent entity (uncommented and improved)
	if parent_entity and is_instance_valid(parent_entity):
		global_position = parent_entity.global_position
		# Also match rotation if the parent rotates
		global_rotation = parent_entity.global_rotation

func _on_body_entered(body: Node2D) -> void:
	if destroyed or not is_active():
		return
		
	DebugLogger.debug("Body Entered on Shield: " + str(body.name), "ShieldComponent")
	
	# Handle FractureBullet collision
	if body is FractureBullet:
		var bullet = body as FractureBullet
		var damage = bullet._ammo_details.damage_final if bullet._ammo_details else 10.0
		var impact_point = bullet.global_position
		
		# Absorb damage and apply fracture effect
		var remaining_damage = absorb_damage(damage, impact_point)
		
		# Stop the bullet (destroy it since shield blocked it)
		bullet.call_deferred("destroy")
		
		DebugLogger.info("Shield blocked bullet, absorbed: {0} damage".format([damage - remaining_damage]))
		return
	
	# Handle other damage sources
	if body.has_method("get_damage"):
		var damage = body.get_damage()
		absorb_damage(damage, body.global_position)
		
		# Try to stop/destroy the damage source
		if body.has_method("destroy"):
			body.call_deferred("destroy")
		elif body.has_method("queue_free"):
			body.call_deferred("queue_free")

func _on_area_entered(area: Area2D) -> void:
	if destroyed or not is_active():
		return
		
	# Handle area collisions (like projectiles that are Area2D)
	if area.has_method("get_damage"):
		var damage = area.get_damage()
		var impact_point = area.global_position
		
		# Absorb damage and apply fracture effect
		var remaining_damage = absorb_damage(damage, impact_point)
		
		# Stop the area-based projectile
		if area.has_method("destroy"):
			area.call_deferred("destroy")
		elif area.has_method("queue_free"):
			area.call_deferred("queue_free")
			
		DebugLogger.info("Shield blocked area projectile, absorbed: {0} damage".format([damage - remaining_damage]))

func _on_regeneration_tick() -> void:
	if destroyed or current_shield >= max_shield:
		regeneration_active = false
		return
	
	# Apply regeneration
	current_shield = min(current_shield + regeneration_amount, max_shield)
	shield_changed.emit(current_shield)
	
	# Continue regenerating if not fully healed
	if current_shield < max_shield:
		_start_regeneration()
	else:
		regeneration_active = false
		# Restore to full visibility when fully healed
		if _polygon2d:
			_polygon2d.visible = true
		if _line2d:
			_line2d.visible = true

func _start_regeneration() -> void:
	if !can_regenerate or destroyed or regeneration_active:
		return
		
	regeneration_active = true
	_regeneration_timer.start()

## Shield damage absorption logic - this is the main entry point from enemy hits
func absorb_damage(amount: float, impact_point_global: Vector2) -> float:
	if destroyed:
		return amount  # Shield is destroyed, all damage passes through
	
	# Reset regeneration timer
	regen_timer = regeneration_delay
	_hit_effect_timer = hit_effect_duration
	
	var absorbed: float = min(amount, current_shield)
	var remaining: float = amount - absorbed
	
	# Apply damage to shield
	current_shield -= absorbed
	shield_changed.emit(self, current_shield)
	
	# Apply visual fracture effect
	if absorbed > 0:
		# _apply_fracture_effect(absorbed, impact_point_global)
		_create_shield_fracture(absorbed, impact_point_global)
	
	# Check if shield is depleted
	if current_shield <= 0:
		_on_shield_depleted()
	else:
		# Start regeneration after delay
		if can_regenerate and regen_timer <= 0 and not regeneration_active:
			_start_regeneration()
	
	# Signal shield damage
	DebugLogger.info("Shield absorbed: {0} damage. Remaining damage: {1}. Remaining shield: {2}".format([absorbed, remaining, current_shield]))
	
	# Return remaining damage that wasn't absorbed
	return remaining

func _apply_fracture_effect(damage_amount: float, impact_point: Vector2) -> void:
	# Create visual fracture effect without actually changing the polygon
	# This could be enhanced with particle effects, screen shake, etc.
	
	# Calculate damage percentage for visual effects
	var _damage_percent = damage_amount / max_shield
	
	# Convert global impact point to local
	var _local_impact = to_local(impact_point)
	
	# Apply visual effects (placeholder for now)
	if _polygon2d.material and _polygon2d.material is ShaderMaterial:
		var shader_mat = _polygon2d.material as ShaderMaterial
		shader_mat.set_shader_parameter("hit_effect", 1.0)
		shader_mat.set_shader_parameter("shield_strength", current_shield / max_shield)

func _create_shield_fracture(damage_amount: float, impact_point_global: Vector2) -> void:
	# Create actual fracture effect on the shield polygon
	if destroyed or original_polygon.is_empty():
		return
	
	# Generate a cut shape based on damage amount
	var damage_vector = Vector2(damage_amount, damage_amount)
	var cut_shape: PackedVector2Array = _poly_fracture.generateRandomPolygon(
		damage_vector, 
		shield_fracture_cut_extents_min_max, 
		Vector2.ZERO
	)
	var cut_shape_area = PolygonLib.getPolygonArea(cut_shape)
	# Calculate minimum area to keep
	var min_area_to_keep = initial_polygon_area * shield_min_area_percent
	
	# Perform fracture
	var fracture_info: Dictionary = _poly_fracture.cutFracture(
		_polygon2d.polygon,
		cut_shape,
		global_transform,
		Transform2D(0.0, impact_point_global),
		min_area_to_keep,
		10.0,  # Min shard area
		5.0,   # Min site distance
		3      # Max fractures
	)

	var p : float = cut_shape_area / current_shield
	for fracture in fracture_info.fractures:
		for shard in fracture:
			fractured.emit(self, shard, 100.0 * (shard.area / current_shield), getCurColor(), 250.0, p)
	
	# Process fracture results
	if fracture_info and fracture_info.has("shapes") and not fracture_info.shapes.is_empty():
		# Find the largest remaining piece
		var largest_area: float = -1.0
		var main_shape: Dictionary = {}
		
		for shape in fracture_info.shapes:
			if shape.area > largest_area:
				largest_area = shape.area
				main_shape = shape
		
		if !main_shape.is_empty():
			# Update shield with fractured polygon
			_setup_shield_polygon(main_shape.shape)
	else:
		# No valid fracture - shield might be too damaged
		if current_shield <= max_shield * 0.1:  # If shield is very low, destroy it
			_on_shield_depleted()

# Shield-specific signal handlers
func _on_shield_damaged(damage_amount: float, impact_point: Vector2) -> void:
	# Any shield-specific effects when damaged
	# Animation, particles, etc.
	print("Shield damaged by: ", damage_amount, " at ", impact_point)

func _on_shield_healed(amount: float) -> void:
	# Shield-specific healing effects
	print("Shield healed by: ", amount)

func _on_health_changed(new_value: float) -> void:
	# Emit shield-specific signal
	shield_changed.emit(new_value)
	
	# Start regeneration if needed
	if can_regenerate and regen_timer <= 0 and new_value < max_shield and not regeneration_active:
		_start_regeneration()

func _on_shield_depleted() -> void:
	shield_depleted.emit()
	destroyed = true
	
	# Make shield invisible
	if _polygon2d:
		_polygon2d.visible = false
	if _line2d:
		_line2d.visible = false

#region Public API
func is_active() -> bool:
	return !destroyed and current_shield > 0

func get_current_shield() -> float:
	return current_shield

func get_max_shield() -> float:
	return max_shield

func reset_shield() -> void:
	current_shield = max_shield
	destroyed = false
	regen_timer = 0.0
	regeneration_active = false
	_hit_effect_timer = 0.0
	
	# Restore original polygon
	if !original_polygon.is_empty():
		_setup_shield_polygon(original_polygon)
	
	# Make shield visible again
	if _polygon2d:
		_polygon2d.visible = true
	if _line2d:
		_line2d.visible = true
	
	shield_changed.emit(current_shield)

func getCurColor() -> Color:
	# Return the current shield color based on its state
	if current_shield > max_shield * 0.5:
		return Color(0.4, 0.7, 1.0, 0.6)  # Healthy shield color
	elif current_shield > max_shield * 0.2:
		return Color(1.0, 0.7, 0.0, 0.6)  # Warning color
	else:
		return Color(1.0, 0.2, 0.2, 0.6)  # Critical color

func set_parent_entity(entity: Node2D) -> void:
	parent_entity = entity
	if parent_entity:
		global_position = parent_entity.global_position
		global_rotation = parent_entity.global_rotation

func get_shield_collision_layer() -> int:
	return collision_layer

func set_shield_collision_layer(layer: int) -> void:
	collision_layer = layer

func get_shield_collision_mask() -> int:
	return collision_mask

func set_shield_collision_mask(mask: int) -> void:
	collision_mask = mask
#endregion
