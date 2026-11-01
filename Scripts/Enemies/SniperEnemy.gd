class_name SniperEnemy extends ShooterEnemy
## Keeps its distance from the player, stands still to aim (a laser sight shows where the shot
## goes) and moves to a new spot around the player after each burst.

@export var preferred_distance: float = 400.0
@export var distance_tolerance: float = 50.0
## Seconds of laser sight shown before each burst. The sniper stops moving while aiming and firing.
@export var aim_time: float = 0.8
@export var aim_color: Color = Color(1.0, 0.15, 0.15, 0.8)
@export var aim_width: float = 2.0
## Speed used while relocating after a burst.
@export var relocate_speed_scale: float = 1.4
@export var relocate_time: float = 1.2

var _aim_line: Line2D
var _relocate_left: float = 0.0
var _clockwise: bool = true

func _ready() -> void:
	super._ready()
	_aim_line = Line2D.new()
	_aim_line.top_level = true
	_aim_line.width = aim_width
	_aim_line.default_color = aim_color
	_aim_line.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	_aim_line.visible = false
	add_child(_aim_line)

func _process(delta: float) -> void:
	super._process(delta)
	_update_aim_line()

func _is_aiming() -> bool:
	return _state == State.COOLDOWN and !_state_timer.is_stopped() and _state_timer.time_left <= aim_time

func _update_aim_line() -> void:
	var threat: Node2D = get_threat()
	var visible_now: bool = threat != null and !isDead() and (_is_aiming() or can_shoot)
	_aim_line.visible = visible_now
	if !visible_now:
		return
	_aim_line.set_point_position(0, global_position)
	_aim_line.set_point_position(1, threat.global_position)
	# Fades in while aiming so the player can read when the shot comes
	var t: float = 1.0 if can_shoot else 1.0 - _state_timer.time_left / maxf(aim_time, 0.001)
	_aim_line.modulate.a = lerpf(0.15, 1.0, t)

func _enter_state(new_state: State) -> void:
	super._enter_state(new_state)
	if new_state == State.COOLDOWN:
		_relocate_left = relocate_time
		_clockwise = _rng.randf() > 0.5

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return Vector2.ZERO
	if can_shoot or _is_aiming():
		return Vector2.ZERO
	var to_target: Vector2 = threat.global_position - global_position
	var current_distance: float = to_target.length()
	if current_distance < preferred_distance - distance_tolerance:
		return -to_target.normalized()
	if current_distance > preferred_distance + distance_tolerance:
		return to_target.normalized()
	# In range: circle to a new firing spot for a bit after each burst, then wait
	if _relocate_left > 0.0:
		_relocate_left -= delta
		move_speed_scale = relocate_speed_scale
		return orbit_direction(threat.global_position, preferred_distance, _clockwise)
	return Vector2.ZERO
