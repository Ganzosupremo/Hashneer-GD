class_name AdvanceCamera extends Camera2D

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
var player: PlayerController
var magnitude: Constants.ShakeMagnitude = Constants.ShakeMagnitude.None

func _ready() -> void:
	player = get_parent()
	shake_timer = Timer.new()
	shake_timer.autostart = false
	shake_timer.one_shot = true
	add_child(shake_timer)
	self.global_position = player.global_position


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
	shake_points = []
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
		offset = Vector2.ZERO
		current_magnitude = Constants.ShakeMagnitude.None
		return
	
	var time_interval: float = 1 / (horizontal_frequency * samples)

	if twenn:
		twenn.stop()
	
	twenn = GameManager.create_tween().set_trans(tween_trans)
	twenn.tween_property(self, "offset", _get_offset(), time_interval)
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
	var viewport_size: Vector2 = player.get_viewport().get_visible_rect().size
	return viewport_size / 2.0
