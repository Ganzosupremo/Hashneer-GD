class_name ChargingEnemy extends BaseEnemy

@export var charge_cooldown_range: Vector2 = Vector2(2.0, 4.0)
@export var charge_duration: float = 0.5
@export var charge_speed: float = 300.0
@export var charge_damage_range: Vector2 = Vector2(10.0, 20.0)

var _charge_timer: Timer
var _charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	super._ready()
	body_entered.connect(_on_body_entered)
	_charge_timer = Timer.new()
	add_child(_charge_timer)
	_charge_timer.timeout.connect(_on_charge_timer_timeout)
	_schedule_next_charge()

func _physics_process(delta: float) -> void:
	if _charging and !is_player_dead:
		linear_velocity = _charge_direction * charge_speed
	else:
		super._physics_process(delta)

func _on_body_entered(body: Node) -> void:
	if _charging and body is PlayerController:
		var args: LevelBuilderArgs = GameManager.get_level_args()
               var dmg = randf_range(charge_damage_range.x, charge_damage_range.y)
               var multiplier = args.enemy_damage_multiplier if args else 1.0
               body.damage(dmg * multiplier, global_position)

func _on_charge_timer_timeout() -> void:
	if _charging:
		_charging = false
		_schedule_next_charge()
	else:
		var player: Node2D = GameManager.player
		if player:
			_charge_direction = (player.global_position - global_position).normalized()
		_charging = true
		_charge_timer.start(charge_duration)

func _schedule_next_charge() -> void:
	if charge_cooldown_range != Vector2.ZERO:
		_charge_timer.start(randf_range(charge_cooldown_range.x, charge_cooldown_range.y))
