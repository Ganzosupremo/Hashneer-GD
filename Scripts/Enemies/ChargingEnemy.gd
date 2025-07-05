class_name ChargingEnemy extends BaseEnemy

@export var charge_cooldown_range: Vector2 = Vector2(2.0, 4.0)
@export var charge_duration: float = 0.5
@export var charge_speed: float = 300.0

var _charge_timer: Timer
var _charging: bool = false
var _charge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
    super._ready()
    _charge_timer = Timer.new()
    add_child(_charge_timer)
    _charge_timer.timeout.connect(_on_charge_timer_timeout)
    _schedule_next_charge()

func _physics_process(delta: float) -> void:
    if _charging:
        linear_velocity = _charge_direction * charge_speed
    else:
        super._physics_process(delta)

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
