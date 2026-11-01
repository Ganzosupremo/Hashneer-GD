class_name SpinnerEnemy extends ShooterEnemy
## Turret: walks to a spot at [member anchor_distance] from the player, then plants itself and
## spins out bullet rings, reversing its spin every volley. Moves again between volleys.

@export var spin_speed: float = 3.0
@export var bullet_spread_count: int = 8
@export var anchor_distance: float = 250.0
## Spin speed multiplier while firing.
@export var firing_spin_multiplier: float = 2.0

var _spin_angle: float = 0.0
var _spin_dir: float = 1.0
var _clockwise: bool = true

func _ready() -> void:
	super._ready()
	rotate_towards_velocity = false
	_clockwise = _rng.randf() > 0.5

func _process(delta: float) -> void:
	super._process(delta)
	_spin_angle += delta * spin_speed * _spin_dir * (firing_spin_multiplier if can_shoot else 1.0)
	global_rotation = _spin_angle

func _enter_state(new_state: State) -> void:
	super._enter_state(new_state)
	if new_state == State.SHOOTING:
		_spin_dir = -_spin_dir

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	if can_shoot:
		return Vector2.ZERO # Planted while firing
	# Slow while settling near its spot, full speed when it fell far behind
	if global_position.distance_squared_to(threat.global_position) < (anchor_distance * 1.5) * (anchor_distance * 1.5):
		move_speed_scale = 0.8
	return orbit_direction(threat.global_position, anchor_distance, _clockwise, 3.0)

## Fires one ring per weapon cooldown. Only the first bullet of the ring used to wait for the
## cooldown: the other ones went out as a "first press" every other frame (~300 bullets/s per
## Spinner), which flooded the enemy bullet pool and dropped the frame rate.
func _fire() -> void:
	if isReadyToFire():
		_fired_previous_frame = true
		if _fire_weapon.fire_rate_cooldown_timer > 0.0:
			return
		for i in range(bullet_spread_count):
			var angle = (TAU / bullet_spread_count) * i + _spin_angle
			var direction: Vector2 = Vector2(cos(angle), sin(angle))
			var target_pos: Vector2 = global_position + direction * 1000.0
			_fire_weapon.fire_weapon.emit(true, false, 1.0, target_pos)
	else:
		_fired_previous_frame = false
		_fire_weapon.fire_weapon.emit(false, _fired_previous_frame, 1.0, _fire_target.global_position)
