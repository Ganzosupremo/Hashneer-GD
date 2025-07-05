class_name Boss extends BaseEnemy

signal target_pos_reached(pos: Vector3)

@export_category("Charge Attack")
@export var charge_cooldown_range: Vector2 = Vector2(1.5, 3.0)
@export var charge_duration: float = 0.6
@export var charge_speed: float = 400.0

enum State { CHASE, CHARGE }
var _state: State = State.CHASE
var _state_timer: Timer
var _charge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
    super._ready()
    target_pos_reached.connect(_on_target_pos_reached)
    _state_timer = Timer.new()
    add_child(_state_timer)
    _state_timer.timeout.connect(_on_state_timer_timeout)
    _enter_state(State.CHASE)

func _physics_process(delta: float) -> void:
    if _state == State.CHARGE:
        linear_velocity = _charge_direction * charge_speed
    else:
        super._physics_process(delta)

func kill(natural_death: bool = false) -> void:
    Died.emit(self, position, natural_death)
    hide()
    if !natural_death:
        random_drops.spawn_drops(1)
        AudioManager.create_2d_audio_at_location(position, sound_on_dead.sound_type, sound_on_dead.destination_audio_bus)
    queue_free()

func _on_target_pos_reached(_pos: Vector3) -> void:
    if target_pos.z == 0.0:
        setNewTargetPos()

func _on_state_timer_timeout() -> void:
    if _state == State.CHARGE:
        _enter_state(State.CHASE)
    else:
        _enter_state(State.CHARGE)

func _enter_state(new_state: State) -> void:
    _state = new_state
    match _state:
        State.CHARGE:
            var player: Node2D = GameManager.player
            if player:
                _charge_direction = (player.global_position - global_position).normalized()
            _state_timer.start(charge_duration)
        State.CHASE:
            if charge_cooldown_range != Vector2.ZERO:
                _state_timer.start(randf_range(charge_cooldown_range.x, charge_cooldown_range.y))
