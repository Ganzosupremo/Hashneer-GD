class_name AdvanceCamera extends Camera2D

@export var target: Node2D
@export_range(0.5, 5.0, 0.5, "or_greater") var smooth_speed: float = 1.0
@export_range(10.0, 100.0, 1.0, "or_greater") var max_distance: float = 50.0


## Movement to side to side
var amplitude: float
## Duration of movement
var duration: float
## How mucht the x-axis will move
var horizontal_weight: float
## How much the y-axis will move
var vertical_weight: float
## The movement's speed on the x-axis
var horizontal_frequency: float
## The movement's speed on the y-axis
var vertical_frequency: float
var phase_offset: float
## Smootheness of the movement
var samples: int = 10

var shake_timer: Timer
var twenn: Tween
var tween_trans: Tween.TransitionType
var current_magnitude: Constants.ShakeMagnitude = Constants.ShakeMagnitude.None
var shake_points: Array[Vector2]
var magnitude: Constants.ShakeMagnitude = Constants.ShakeMagnitude.None
var target_position: Vector2 = Vector2.INF

# Trauma-based shake system
var trauma: float = 0.0
var trauma_decay_rate: float = 1.0  # Trauma decreases per second
var max_trauma: float = 1.0
var trauma_power: float = 2.0  # Exponential for shake strength

# Recoil kick system
var recoil_offset: Vector2 = Vector2.ZERO
var recoil_decay_rate: float = 8.0

## Constant shake variables
var is_constant_shake_active: bool = false
var constant_shake_amplitude: float = 0.0
var constant_shake_frequency: float = 0.0
var constant_shake_axis_ratio: float = 0.0
var constant_shake_horizontal_weight: float = 1.0
var constant_shake_vertical_weight: float = 1.0
var constant_shake_horizontal_frequency: float = 5.0
var constant_shake_vertical_frequency: float = 5.0
var constant_shake_phase_offset: float = 0.0
var constant_shake_start_time: float = 0.0

func _ready() -> void:
	GameManager.player_camera = self
	shake_timer = Timer.new()
	shake_timer.autostart = false
	shake_timer.one_shot = true
	add_child(shake_timer)

func _process(delta: float) -> void:
	if target != null:
		target_position = target.position

		# var mouse_pos: Vector2 = get_local_mouse_position()
		# target_position = target_position + mouse_pos
		target_position.x = clamp(target_position.x, -max_distance + target_position.x, max_distance + target_position.x)
		target_position.y = clamp(target_position.y, -max_distance + target_position.y, max_distance + target_position.y)

	if target_position != Vector2.INF:
		position = lerp(position, target_position, smooth_speed * delta)
	
	# Decay trauma over time
	if trauma > 0.0:
		trauma = max(trauma - trauma_decay_rate * delta, 0.0)
		
		# Decay recoil kick
	if recoil_offset.length() > 0.1:
		recoil_offset = recoil_offset.lerp(Vector2.ZERO, recoil_decay_rate * delta)
	else:
		recoil_offset = Vector2.ZERO
		
	# Apply trauma-based shake
	var trauma_shake = Vector2.ZERO
	if trauma > 0.0:
		var shake_amount = pow(trauma, trauma_power)
		trauma_shake = Vector2(
			randf_range(-1.0, 1.0) * shake_amount * 10.0,
			randf_range(-1.0, 1.0) * shake_amount * 10.0
		)

	# Handle constant shake
	if is_constant_shake_active:
		offset = _get_constant_shake_offset()

func shake(_amplitude: float = 3.0, _frequency: float = 5.0, _duration: float = 0.5, _axis_ratio: float = 0.0, _armonic_ratio: Array[int] = [1,1], _phase_offset_degrees: int  = 90, _samples: int = 10, _tween_trans: Tween.TransitionType = Tween.TransitionType.TRANS_SPRING) -> void:
	amplitude = _amplitude
	duration = _duration
	vertical_weight = clampf(_axis_ratio, -1.0, 0.0) + 1.0 if _axis_ratio < 0.0 else 1.0
	horizontal_weight = 1.0 - clampf(_axis_ratio, 0.0, 1.0) + 1.0 if _axis_ratio > 0.0 else 1.0
	horizontal_frequency = _frequency * _armonic_ratio[1]
	vertical_frequency = _frequency * _armonic_ratio[0]
	phase_offset = deg_to_rad(_phase_offset_degrees)
	samples = _samples
	tween_trans = _tween_trans

	shake_timer.start(duration)
	shake_points.clear()
	_tween_offset()

func shake_with_preset(_magnitude: Constants.ShakeMagnitude = Constants.ShakeMagnitude.None) -> void:
	current_magnitude = _magnitude
	match magnitude:
		Constants.ShakeMagnitude.Small:
			shake(1.5, 2.5, .25, 0.0, [4,5], 90, 8, Tween.TransitionType.TRANS_SPRING)
		Constants.ShakeMagnitude.Medium:
			shake(3.0, 5.0, .5, 0.0, [4,5], 90, 10, Tween.TransitionType.TRANS_SPRING)
		Constants.ShakeMagnitude.Large:
			shake(4.5, 7.5, 1.0, 0.0, [4,5], 45, 11, Tween.TransitionType.TRANS_SPRING)
		Constants.ShakeMagnitude.ExtraLarge:
			shake(6.0, 10.0, 1.5, 5, [4,5], 45, 12, Tween.TransitionType.TRANS_SPRING)
		Constants.ShakeMagnitude.Gigantius:
			shake(7.5, 12.5, 2.0, 10, [4,5], 135, 15, Tween.TransitionType.TRANS_SPRING)
		Constants.ShakeMagnitude.Enormius:
			shake(10.0, 15.0, 2.5, 15, [5,6], 90, 18, Tween.TransitionType.TRANS_SPRING)

func _tween_offset() -> void:
	if _get_current_duration() >= duration:
		current_magnitude = Constants.ShakeMagnitude.None
		# Only reset offset if no constant shake is active
		if not is_constant_shake_active:
			offset = Vector2.ZERO
		return
	
	var time_interval: float = 1 / (horizontal_frequency * samples)

	if twenn:
		twenn.stop()
	
	twenn = GameManager.create_tween().set_trans(tween_trans)
	var target_offset = _get_offset()
	
	# Combine regular shake with constant shake if both are active
	if is_constant_shake_active:
		target_offset += _get_constant_shake_offset()
	
	twenn.tween_property(self, "offset", target_offset, time_interval)
	twenn.play()
	twenn.tween_callback(_tween_offset)
	
func _get_offset() -> Vector2:
	var Ax: float = _get_amplitude(_get_current_duration()) * horizontal_weight
	var Ay: float = _get_amplitude(_get_current_duration()) * vertical_weight
	var t: float = _get_current_duration() * 2.0 * PI
	
	var Wx: float = horizontal_frequency
	var Wy: float = vertical_frequency

	var horizontal_component: float = Ax * sin(Wx * t)
	var vertical_component: float = Ay * sin(Wy * t + phase_offset)
	shake_points.push_back(Vector2(horizontal_component, -vertical_component) * 3)
	return Vector2(horizontal_component, -vertical_component)

func _get_amplitude(current_duration: float) -> float:
	var acceleration_time_percent: float = 0.1
	var deceleration_time_percent: float = 0.6
	var constant_time_percent: float = (1 - acceleration_time_percent - deceleration_time_percent)

	if current_duration < acceleration_time_percent * duration:
		var m: float = amplitude / (acceleration_time_percent * duration)
		var y: float = m * current_duration
		return y
	elif current_duration < (acceleration_time_percent * constant_time_percent) * duration:
		return amplitude
	else:
		var previous_time: float = (acceleration_time_percent + constant_time_percent) * duration
		var m: float = -amplitude / (deceleration_time_percent * duration)
		var b: float = amplitude
		var y: float = m * (current_duration - previous_time) + b
		return y

func _get_current_duration() -> float:
	return shake_timer.wait_time - shake_timer.time_left

func _get_center_viewport() -> Vector2:
	var viewport_size: Vector2 = target.get_viewport().get_visible_rect().size
	return viewport_size / 2.0

## Starts a constant camera shake that continues until stopped
## This is useful for continuous effects like laser beams or machinery
func start_constant_shake(_amplitude: float = 2.0, _frequency: float = 8.0, _axis_ratio: float = 0.0, _harmonic_ratio: Array[int] = [1,1], _phase_offset_degrees: int = 90) -> void:
   # Stop any ongoing transient shake
	if shake_timer and not shake_timer.is_stopped():
		shake_timer.stop()
	if twenn:
		twenn.stop()
	current_magnitude = Constants.ShakeMagnitude.None
	offset = Vector2.ZERO
	if is_constant_shake_active:
		stop_constant_shake()
	# Initialize constant shake parameters
	constant_shake_amplitude = _amplitude
	constant_shake_axis_ratio = _axis_ratio
	constant_shake_vertical_weight = clampf(_axis_ratio, -1.0, 0.0) + 1.0 if _axis_ratio < 0.0 else 1.0
	constant_shake_horizontal_weight = 1.0 - clampf(_axis_ratio, 0.0, 1.0) + 1.0 if _axis_ratio > 0.0 else 1.0
	constant_shake_horizontal_frequency = _frequency * _harmonic_ratio[1]
	constant_shake_vertical_frequency = _frequency * _harmonic_ratio[0]
	constant_shake_phase_offset = deg_to_rad(_phase_offset_degrees)
	# Record start time
	constant_shake_start_time = Time.get_unix_time_from_system()
	# Activate constant shake
	is_constant_shake_active = true

## Starts constant shake with a preset magnitude
func start_constant_shake_with_preset(_magnitude: Constants.ShakeMagnitude = Constants.ShakeMagnitude.Small) -> void:
	match _magnitude:
		Constants.ShakeMagnitude.Small:
			start_constant_shake(1.0, 6.0, 0.0, [2,3], 90)
		Constants.ShakeMagnitude.Medium:
			start_constant_shake(2.0, 8.0, 0.0, [2,3], 90)
		Constants.ShakeMagnitude.Large:
			start_constant_shake(3.0, 10.0, 0.0, [3,4], 45)
		Constants.ShakeMagnitude.ExtraLarge:
			start_constant_shake(4.0, 12.0, 0.0, [3,4], 45)
		Constants.ShakeMagnitude.Gigantius:
			start_constant_shake(5.0, 15.0, 0.0, [4,5], 135)
		Constants.ShakeMagnitude.Enormius:
			start_constant_shake(6.0, 18.0, 0.0, [4,5], 90)

## Stops the constant camera shake
func stop_constant_shake() -> void:
	is_constant_shake_active = false
	# Stop any constant shake processing
	# Only reset offset if no regular shake is active
	if current_magnitude == Constants.ShakeMagnitude.None:
		offset = Vector2.ZERO
## Returns true if constant shake is currently active
func is_constant_shake_running() -> bool:
	return is_constant_shake_active

## Calculates the offset for constant shake
func _get_constant_shake_offset() -> Vector2:
	# Calculate elapsed time in seconds with high resolution
	# Calculate elapsed time in seconds
	var current_time_usec = Time.get_unix_time_from_system()
	var elapsed_time = float(current_time_usec - constant_shake_start_time) / 1000000.0
	
	var Ax: float = constant_shake_amplitude * constant_shake_horizontal_weight
	var Ay: float = constant_shake_amplitude * constant_shake_vertical_weight
	var t: float = elapsed_time * 2.0 * PI
	
	var Wx: float = constant_shake_horizontal_frequency
	var Wy: float = constant_shake_vertical_frequency

	var horizontal_component: float = Ax * sin(Wx * t)
	var vertical_component: float = Ay * sin(Wy * t + constant_shake_phase_offset)
	
	return Vector2(horizontal_component, -vertical_component)


## Adds trauma to the camera for procedural shake.[br]
## [param amount] Amount of trauma to add (0.0 to 1.0)
func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, max_trauma)

## Adds trauma with preset magnitudes
func add_trauma_preset(_magnitude: Constants.ShakeMagnitude) -> void:
	match _magnitude:
		Constants.ShakeMagnitude.Small:
			add_trauma(0.15)
		Constants.ShakeMagnitude.Medium:
			add_trauma(0.35)
		Constants.ShakeMagnitude.Large:
			add_trauma(0.6)
		Constants.ShakeMagnitude.ExtraLarge:
			add_trauma(0.8)
		Constants.ShakeMagnitude.Gigantius:
			add_trauma(1.0)

## Kicks the camera in a specific direction (for recoil).[br]
## [param direction] Angle in radians for the kick direction.[br]
## [param strength] Strength of the kick in pixels.
func kick(direction: float, strength: float = 5.0) -> void:
	var kick_vector = Vector2(cos(direction), sin(direction)) * strength
	recoil_offset += kick_vector

## Quick recoil kick opposite to aim direction (for weapon fire).[br]
## [param aim_angle] Current aim angle in radians.[br]
## [param strength] Recoil strength.
func recoil_kick(aim_angle: float, strength: float = 3.0) -> void:
	kick(aim_angle + PI, strength)  # Kick opposite to aim direction
