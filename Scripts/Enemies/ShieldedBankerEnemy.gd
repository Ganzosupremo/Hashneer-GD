class_name ShieldedBankerEnemy extends BaseEnemy
## Enemy that walks towards the player behind a frontal guard.
## Hits that land inside the guard arc deal only a fraction of their damage,
## so the player has to flank it, use explosions or bounce bullets. The guard turns slowly, so
## circling around it works, and up close it lunges forward with a shield bash.

## Fraction of the damage blocked by the guard.
@export_range(0.0, 1.0, 0.05) var guard_damage_reduction: float = 0.85
## Half of the guard arc, in degrees.
@export_range(10.0, 180.0, 5.0) var guard_half_angle_deg: float = 65.0
@export var guard_color: Color = Color(1.0, 0.8, 0.2)
@export var guard_width: float = 8.0
## How fast the guard turns to face the player, in degrees per second.
@export var guard_turn_speed_deg: float = 90.0
@export_group("Shield Bash", "bash_")
@export var bash_range: float = 190.0
@export var bash_cooldown_range: Vector2 = Vector2(3.0, 4.5)
@export var bash_windup_time: float = 0.45
@export var bash_time: float = 0.3
@export var bash_speed_scale: float = 6.0
@export var bash_damage_range: Vector2 = Vector2(12.0, 18.0)

var _guard_line: Line2D
var _guard_cos: float = 0.0
var _facing: Vector2 = Vector2.RIGHT
var _bash_cooldown: float = 0.0
var _bash_windup_left: float = 0.0
var _bash_left: float = 0.0
var _bash_hit: bool = false

func _ready() -> void:
	super._ready()
	_guard_cos = cos(deg_to_rad(guard_half_angle_deg))
	var player: Node2D = GameManager.get_player()
	if player:
		setTarget(player)
	var threat: Node2D = get_threat()
	if threat:
		_facing = global_position.direction_to(threat.global_position)
	_bash_cooldown = _rng.randf_range(bash_cooldown_range.x, bash_cooldown_range.y)
	_create_guard_line()

func _process(delta: float) -> void:
	super._process(delta)
	_turn_guard(delta)
	if _guard_line and !isDead():
		_guard_line.global_rotation = _facing.angle()

func _turn_guard(delta: float) -> void:
	var threat: Node2D = get_threat()
	# The guard is locked during the bash
	if threat == null or _bash_left > 0.0 or _bash_windup_left > 0.0:
		return
	var wanted: Vector2 = threat.global_position - global_position
	if wanted == Vector2.ZERO:
		return
	var diff: float = _facing.angle_to(wanted)
	var max_step: float = deg_to_rad(guard_turn_speed_deg) * delta
	_facing = _facing.rotated(clampf(diff, -max_step, max_step))

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		_bash_windup_left = 0.0
		_bash_left = 0.0
		return super._get_movement_input(delta)
	if _bash_windup_left > 0.0:
		_bash_windup_left -= delta
		if _bash_windup_left <= 0.0:
			_bash_left = bash_time
			_bash_hit = false
		return Vector2.ZERO
	if _bash_left > 0.0:
		_bash_left -= delta
		if !_bash_hit and is_touching(threat, guard_width):
			_bash_hit = true
			deal_damage_to_player(bash_damage_range, true)
			if threat is PlayerController:
				threat.apply_slow(0.5, 0.6)
		move_speed_scale = bash_speed_scale
		linear_velocity = _facing * getCurMaxSpeed() * bash_speed_scale
		return _facing
	_bash_cooldown -= delta
	if _bash_cooldown <= 0.0 and global_position.distance_squared_to(threat.global_position) < bash_range * bash_range:
		_bash_cooldown = _rng.randf_range(bash_cooldown_range.x, bash_cooldown_range.y)
		_bash_windup_left = bash_windup_time
		_flash_guard()
		return Vector2.ZERO
	return super._get_movement_input(delta)

func damage(damage_to_apply: Vector2, point: Vector2, knockback_force: Vector2, knockback_time: float, damage_color: Color) -> Dictionary:
	if _is_guarded(point):
		_flash_guard()
		damage_to_apply *= (1.0 - guard_damage_reduction)
		knockback_force *= (1.0 - guard_damage_reduction)
	return super.damage(damage_to_apply, point, knockback_force, knockback_time, damage_color)

func _is_guarded(point: Vector2) -> bool:
	var to_hit: Vector2 = point - global_position
	if to_hit == Vector2.ZERO:
		return false
	return to_hit.normalized().dot(_get_facing()) >= _guard_cos

func _get_facing() -> Vector2:
	return _facing

func _create_guard_line() -> void:
	_guard_line = Line2D.new()
	_guard_line.width = guard_width
	_guard_line.default_color = guard_color
	_guard_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_guard_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var radius: float = maxf(getPolygonRect().size.x, getPolygonRect().size.y) * 0.5 + 14.0
	var half: float = deg_to_rad(guard_half_angle_deg)
	var steps: int = 12
	for i in range(steps + 1):
		var a: float = lerpf(-half, half, float(i) / steps)
		_guard_line.add_point(Vector2.RIGHT.rotated(a) * radius)
	add_child(_guard_line)

func _flash_guard() -> void:
	if _guard_line == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_guard_line, "modulate", Color(2.0, 2.0, 2.0), 0.05)
	tween.tween_property(_guard_line, "modulate", Color.WHITE, 0.15)
