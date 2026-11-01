class_name FastDartEnemy extends BaseEnemy
## Hit and run: darts at the player (with quick sidesteps on the way), and once it gets close
## it turns around, runs off for a moment and comes back for another pass.

@export var dodge_interval_range: Vector2 = Vector2(0.8, 1.5)
@export var dodge_distance: float = 150.0
@export var dodge_speed_multiplier: float = 2.0
## Distance to the player that ends an attack run.
@export var strike_distance: float = 70.0
@export var retreat_time_range: Vector2 = Vector2(0.8, 1.3)
@export var retreat_speed_scale: float = 0.9

var _dodge_timer: Timer
var _is_dodging: bool = false
var _dodge_target: Vector2 = Vector2.ZERO
var _retreat_left: float = 0.0
var _retreat_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()
	_dodge_timer = Timer.new()
	add_child(_dodge_timer)
	_dodge_timer.timeout.connect(_on_dodge_timer_timeout)
	_schedule_next_dodge()

func _physics_process(delta: float) -> void:
	if isKnockbackActive(): 
		return
	
	if _is_dodging and !is_player_dead:
		_handle_screen_wrapping()
		_process_contact_damage(delta)
		var direction = (_dodge_target - global_position).normalized()
		linear_velocity = direction * max_speed * dodge_speed_multiplier
		if rotate_towards_velocity:
			global_rotation = direction.angle()
		
		if global_position.distance_squared_to(_dodge_target) < 100:
			_is_dodging = false
	else:
		super._physics_process(delta)

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	if _retreat_left > 0.0:
		_retreat_left -= delta
		move_speed_scale = retreat_speed_scale
		return _retreat_dir
	var to_threat: Vector2 = threat.global_position - global_position
	if to_threat.length_squared() < strike_distance * strike_distance:
		# Peel off away from the player, a bit to the side so it doesn't just reverse
		_retreat_left = _rng.randf_range(retreat_time_range.x, retreat_time_range.y)
		_retreat_dir = (-to_threat.normalized()).rotated(_rng.randf_range(-0.6, 0.6))
		return _retreat_dir
	return to_threat.normalized()

func _on_dodge_timer_timeout() -> void:
	_schedule_next_dodge()
	# Only sidestep on the way in
	if is_player_dead or _is_dodging or _retreat_left > 0.0:
		return
	
	var perpendicular = Vector2(-linear_velocity.y, linear_velocity.x).normalized()
	if randf() > 0.5:
		perpendicular = -perpendicular
	
	_dodge_target = global_position + perpendicular * dodge_distance
	_is_dodging = true

func _schedule_next_dodge() -> void:
	if dodge_interval_range != Vector2.ZERO:
		_dodge_timer.start(randf_range(dodge_interval_range.x, dodge_interval_range.y))
