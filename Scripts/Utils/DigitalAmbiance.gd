class_name DigitalAmbiance extends Node2D
## Creates digital/cyber ambient effects for the mining world
##
## This class adds visual effects like scan lines, glitch effects, and floating particles
## to create a digital/cyberpunk atmosphere in the mining game mode.

@export var scan_line_speed: float = 50.0
@export var glitch_frequency: float = 0.1
@export var scan_line_color: Color = Color(0.3, 0.8, 1.0, 0.3)
@export var number_of_scan_lines: int = 3

var _scan_lines: Array[Line2D] = []
var _world_bounds: Rect2
var _glitch_timer: float = 0.0

func _ready() -> void:
	_create_scan_lines()

## Set the bounds where the ambiance effects should appear
func set_world_bounds(bounds: Rect2) -> void:
	_world_bounds = bounds
	_position_scan_lines()

func _create_scan_lines() -> void:
	# Create horizontal scan lines that move down
	for i in range(number_of_scan_lines):
		var line = Line2D.new()
		line.default_color = scan_line_color
		line.width = 2.0
		line.z_index = 100  # Above everything else
		add_child(line)
		_scan_lines.append(line)

func _position_scan_lines() -> void:
	if _world_bounds.size == Vector2.ZERO:
		return
	
	# Position scan lines at different heights
	for i in range(_scan_lines.size()):
		var line = _scan_lines[i]
		var y_offset = (_world_bounds.size.y / (_scan_lines.size() + 1)) * (i + 1)
		line.position.y = _world_bounds.position.y + y_offset
		
		# Set line points (horizontal across world)
		line.clear_points()
		line.add_point(Vector2(_world_bounds.position.x, 0))
		line.add_point(Vector2(_world_bounds.end.x, 0))

func _process(delta: float) -> void:
	if _scan_lines.is_empty() or _world_bounds.size == Vector2.ZERO:
		return
	
	_animate_scan_lines(delta)
	_process_glitch_effect(delta)

func _animate_scan_lines(delta: float) -> void:
	for i in range(_scan_lines.size()):
		var line = _scan_lines[i]
		line.position.y += scan_line_speed * delta
		
		# Wrap around when reaching bottom
		if line.position.y > _world_bounds.end.y:
			line.position.y = _world_bounds.position.y
		
		# Pulsing effect based on position
		var progress = (line.position.y - _world_bounds.position.y) / _world_bounds.size.y
		var alpha = 0.2 + sin(progress * PI) * 0.2
		line.default_color.a = alpha

func _process_glitch_effect(delta: float) -> void:
	_glitch_timer += delta
	
	# Random glitches
	if _glitch_timer > 1.0 / glitch_frequency and randf() < glitch_frequency * delta:
		_trigger_glitch()
		_glitch_timer = 0.0

func _trigger_glitch() -> void:
	# Brief color shift effect
	modulate = Color(1.2, 1.2, 1.3, 1.0)
	
	# Randomly offset scan lines
	for line in _scan_lines:
		line.position.x = randf_range(-5, 5)
	
	# Reset after short delay
	await get_tree().create_timer(0.05).timeout
	
	modulate = Color.WHITE
	for line in _scan_lines:
		line.position.x = 0

## Add floating digital particles effect
func add_data_particles() -> void:
	var particles = GPUParticles2D.new()
	particles.name = "DataParticles"
	particles.amount = 30
	particles.lifetime = 8.0
	particles.position = Vector2(_world_bounds.size.x / 2, _world_bounds.position.y)
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(_world_bounds.size.x / 2, 10, 0)
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = 20.0
	particle_material.initial_velocity_max = 50.0
	particle_material.gravity = Vector3(0, 10, 0)
	particle_material.scale_min = 1.0
	particle_material.scale_max = 2.0
	particle_material.color = Color(0.5, 0.8, 1.0, 0.4)
	
	particles.process_material = particle_material
	add_child(particles)
	particles.emitting = true

## Create scanline effect for specific area (e.g., when mining)
func create_scan_burst(burst_position: Vector2) -> void:
	var burst_line = Line2D.new()
	burst_line.default_color = Color(0.5, 1.0, 1.0, 0.8)
	burst_line.width = 3.0
	burst_line.z_index = 150
	
	# Horizontal line expanding from center
	burst_line.add_point(Vector2(burst_position.x, 0))
	burst_line.add_point(Vector2(burst_position.x, 0))
	burst_line.position.y = burst_position.y
	add_child(burst_line)
	
	# Animate expansion
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(
		func(val: float): 
			burst_line.set_point_position(0, Vector2(burst_position.x - val, 0))
			burst_line.set_point_position(1, Vector2(burst_position.x + val, 0)),
		0.0,
		_world_bounds.size.x / 2,
		0.5
	)
	tween.tween_property(burst_line, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	burst_line.queue_free()
