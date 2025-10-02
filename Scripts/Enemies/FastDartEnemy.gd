class_name FastDartEnemy extends BaseEnemy

@export var dodge_interval_range: Vector2 = Vector2(0.8, 1.5)
@export var dodge_distance: float = 150.0
@export var dodge_speed_multiplier: float = 2.0

var _dodge_timer: Timer
var _is_dodging: bool = false
var _dodge_target: Vector2 = Vector2.ZERO

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
		var direction = (_dodge_target - global_position).normalized()
		linear_velocity = direction * max_speed * dodge_speed_multiplier
		if rotate_towards_velocity:
			global_rotation = direction.angle()
		
		if global_position.distance_squared_to(_dodge_target) < 100:
			_is_dodging = false
	else:
		super._physics_process(delta)

func _on_dodge_timer_timeout() -> void:
	if is_player_dead or _is_dodging:
		return
	
	var perpendicular = Vector2(-linear_velocity.y, linear_velocity.x).normalized()
	if randf() > 0.5:
		perpendicular = -perpendicular
	
	_dodge_target = global_position + perpendicular * dodge_distance
	_is_dodging = true
	_schedule_next_dodge()

func _schedule_next_dodge() -> void:
	if dodge_interval_range != Vector2.ZERO:
		_dodge_timer.start(randf_range(dodge_interval_range.x, dodge_interval_range.y))
