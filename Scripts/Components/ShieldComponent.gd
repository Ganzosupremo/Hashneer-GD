class_name ShieldComponent extends FracturablePolygon2D

signal shield_depleted()
signal shield_changed(new_value: float)

@export_category("Shield Settings")
@export var shield_visibility_scale: float = 1.2  # Makes the shield visibly larger than its collision area

@export_group("Fracture Settings")
## Min/Max extents for the random cutting polygon generation
@export var shield_fracture_cut_extents_min_max: Vector2 = Vector2(20, 50) 
## Min percentage of area to keep after fracture
@export var shield_min_area_percent: float = 0.1 
  
@export_group("Visual Effects")
@export var hit_effect_duration: float = 1.0

var _hit_effect_timer: float = 0.0

func _ready() -> void:
	super()
	
	# Shield-specific setup
	if _polygon2d:
		_polygon2d.scale = Vector2.ONE * shield_visibility_scale
	
	# Connect parent signals to shield-specific signals
	entity_damaged.connect(_on_shield_damaged)
	entity_healed.connect(_on_shield_healed)
	health.health_changed.connect(_on_health_changed)
	health.zero_health.connect(_on_shield_depleted)

func _process(delta: float) -> void:
	super(delta)
	
	# Handle shield-specific hit effect fade
	if _hit_effect_timer > 0:
		_hit_effect_timer -= delta * 2.0
		# Could update visual effects based on _hit_effect_timer

# Shield damage absorption logic - this is the main entry point from enemy hits
func absorb_damage(amount: float, impact_point_global: Vector2) -> float:
	if destroyed:
		return amount  # Shield is destroyed, all damage passes through
	
	# Reset regeneration timer
	regen_timer = regeneration_delay
	_hit_effect_timer = hit_effect_duration
	
	var current_shield = health.get_current_health()
	var max_shield = health.get_max_health()
	var absorbed = min(amount, current_shield)
	var remaining = amount - absorbed
	
	# Create damage vector for fracturing (x and y set to same value for simplicity)
	var damage_vector = Vector2(absorbed, absorbed)
	
	# Use parent class fracture functionality
	damage_with_fracture(
		damage_vector,
		impact_point_global,
		shield_fracture_cut_extents_min_max,
		shield_min_area_percent
	)
	
	# Return remaining damage that wasn't absorbed
	return remaining

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
	if can_regenerate and regen_timer <= 0 and new_value < health.get_max_health() and not regeneration_active:
		start_regeneration()

func _on_shield_depleted() -> void:
	shield_depleted.emit()
	
	# Make shield invisible
	if _polygon2d:
		_polygon2d.visible = false
	if _line2d:
		_line2d.visible = false

#region Public API
func is_active() -> bool:
	return not destroyed and health.get_current_health() > 0

func get_current_shield() -> float:
	return health.get_current_health()

func get_max_shield() -> float:
	return health.get_max_health()

func reset_shield() -> void:
	reset_entity()
#endregion
