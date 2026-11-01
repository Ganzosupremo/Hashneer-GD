class_name TeleporterEnemy extends BaseEnemy
## Blinks next to the player, preferably behind them, holds still for a split second and then
## lunges. Between blinks it keeps its distance.

@export var teleport_interval_range: Vector2 = Vector2(3.0, 6.0)
## Distance from the player it reappears at.
@export var teleport_distance_range: Vector2 = Vector2(160.0, 240.0)
@export var teleport_fade_time: float = 0.2
## Pause after reappearing before the lunge, so the player can react.
@export var lunge_delay: float = 0.3
@export var lunge_time: float = 0.45
@export var lunge_speed_scale: float = 2.8
## Distance it hovers at between blinks.
@export var hover_distance: float = 380.0

var _teleport_timer: Timer
var _is_teleporting: bool = false
var _lunge_delay_left: float = 0.0
var _lunge_left: float = 0.0
var _lunge_dir: Vector2 = Vector2.ZERO
var _clockwise: bool = true

func _ready() -> void:
	super._ready()
	_clockwise = _rng.randf() > 0.5
	_teleport_timer = Timer.new()
	add_child(_teleport_timer)
	_teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	_schedule_next_teleport()

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	if _is_teleporting:
		return Vector2.ZERO
	if _lunge_delay_left > 0.0:
		_lunge_delay_left -= delta
		if _lunge_delay_left <= 0.0:
			_lunge_left = lunge_time
			_lunge_dir = global_position.direction_to(threat.global_position)
			linear_velocity = _lunge_dir * max_speed * lunge_speed_scale
		return Vector2.ZERO
	if _lunge_left > 0.0:
		_lunge_left -= delta
		move_speed_scale = lunge_speed_scale
		return _lunge_dir
	return orbit_direction(threat.global_position, hover_distance, _clockwise)

func _on_teleport_timer_timeout() -> void:
	if is_player_dead or _is_teleporting or isDead():
		_schedule_next_teleport()
		return
	_teleport()
	_schedule_next_teleport()

func _teleport() -> void:
	_is_teleporting = true
	
	var tween: Tween = create_tween()
	tween.tween_property(_polygon, "modulate:a", 0.0, teleport_fade_time)
	tween.parallel().tween_property(_line, "modulate:a", 0.0, teleport_fade_time)
	
	await tween.finished
	if !is_instance_valid(self) or isDead():
		return
	
	global_position = _pick_teleport_position()
	linear_velocity = Vector2.ZERO
	
	var tween2: Tween = create_tween()
	tween2.tween_property(_polygon, "modulate:a", 1.0, teleport_fade_time)
	tween2.parallel().tween_property(_line, "modulate:a", 1.0, teleport_fade_time)
	
	await tween2.finished
	_is_teleporting = false
	_lunge_delay_left = lunge_delay

## A spot near the player, behind them when they are moving.
func _pick_teleport_position() -> Vector2:
	var distance: float = _rng.randf_range(teleport_distance_range.x, teleport_distance_range.y)
	var player: PlayerController = GameManager.get_player()
	if player == null:
		return global_position + Vector2.RIGHT.rotated(_rng.randf() * TAU) * distance
	var angle: float = _rng.randf() * TAU
	if player.velocity.length_squared() > 400.0:
		angle = (-player.velocity).angle() + _rng.randf_range(-0.8, 0.8)
	return player.global_position + Vector2.RIGHT.rotated(angle) * distance

func _schedule_next_teleport() -> void:
	if teleport_interval_range != Vector2.ZERO:
		_teleport_timer.start(randf_range(teleport_interval_range.x, teleport_interval_range.y))
