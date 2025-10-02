class_name SpinnerEnemy extends ShooterEnemy

@export var spin_speed: float = 3.0
@export var bullet_spread_count: int = 8

var _spin_angle: float = 0.0

func _ready() -> void:
	super._ready()
	rotate_towards_velocity = false

func _process(delta: float) -> void:
	super._process(delta)
	_spin_angle += delta * spin_speed
	global_rotation = _spin_angle

func _fire() -> void:
	if isReadyToFire():
		_fired_previous_frame = true
		for i in range(bullet_spread_count):
			var angle = (TAU / bullet_spread_count) * i + _spin_angle
			var direction = Vector2(cos(angle), sin(angle))
			var target_pos = global_position + direction * 1000.0
			_fire_weapon.fire_weapon.emit(true, i == 0, 1.0, target_pos)
	else:
		_fired_previous_frame = false
		_fire_weapon.fire_weapon.emit(false, _fired_previous_frame, 1.0, _fire_target.global_position)
