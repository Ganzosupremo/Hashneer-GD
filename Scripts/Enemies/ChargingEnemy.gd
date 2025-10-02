class_name ChargingEnemy extends BaseEnemy

@export var charge_cooldown_range: Vector2 = Vector2(2.0, 4.0)
@export var charge_windup_time: float = 0.3
@export var charge_duration: float = 0.5
@export var charge_speed: float = 600.0
@export var charge_damage_range: Vector2 = Vector2(10.0, 20.0)
@export var charge_color: Color = Color(1.0, 0.3, 0.3)

enum ChargeState { IDLE, WINDING_UP, CHARGING, COOLDOWN }

var _charge_state: ChargeState = ChargeState.COOLDOWN
var _charge_timer: Timer
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_hit_bodies: Array[Node] = []
var _original_color: Color

func _ready() -> void:
	super._ready()
	_original_color = color_default
	body_entered.connect(_on_body_entered)
	_charge_timer = Timer.new()
	add_child(_charge_timer)
	_charge_timer.timeout.connect(_on_charge_timer_timeout)
	_schedule_next_charge()

func _physics_process(delta: float) -> void:
	if isKnockbackActive(): 
		return
	
	if _charge_state == ChargeState.CHARGING and !is_player_dead:
		_handle_screen_wrapping()
		linear_velocity = _charge_direction * charge_speed
		if rotate_towards_velocity:
			global_rotation = _charge_direction.angle()
	elif _charge_state == ChargeState.WINDING_UP:
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, delta * 10.0)
	else:
		super._physics_process(delta)

func _on_body_entered(body: Node) -> void:
	if _charge_state == ChargeState.CHARGING and body is PlayerController:
		if not _charge_hit_bodies.has(body):
			_charge_hit_bodies.append(body)
			var args: LevelBuilderArgs = GameManager.get_level_args()
			var dmg = randf_range(charge_damage_range.x, charge_damage_range.y)
			var multiplier = args.enemy_damage_multiplier if args else 1.0
			body.damage(dmg * multiplier, global_position)

func _on_charge_timer_timeout() -> void:
	match _charge_state:
		ChargeState.WINDING_UP:
			_start_charge()
		ChargeState.CHARGING:
			_end_charge()
		ChargeState.COOLDOWN:
			_windup_charge()

func _windup_charge() -> void:
	if is_player_dead:
		_schedule_next_charge()
		return
	
	var player: Node2D = GameManager.player
	if player:
		_charge_direction = (player.global_position - global_position).normalized()
	
	_charge_state = ChargeState.WINDING_UP
	applyColor(charge_color)
	_charge_timer.start(charge_windup_time)

func _start_charge() -> void:
	_charge_state = ChargeState.CHARGING
	_charge_hit_bodies.clear()
	applyColor(charge_color.lightened(0.3))
	_charge_timer.start(charge_duration)

func _end_charge() -> void:
	_charge_state = ChargeState.COOLDOWN
	applyColor(_original_color)
	_schedule_next_charge()

func _schedule_next_charge() -> void:
	_charge_state = ChargeState.COOLDOWN
	if charge_cooldown_range != Vector2.ZERO:
		_charge_timer.start(randf_range(charge_cooldown_range.x, charge_cooldown_range.y))
