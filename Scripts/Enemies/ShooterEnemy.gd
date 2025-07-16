class_name ShooterEnemy extends BaseEnemy

@export_category("Shooting")
## If true, the enemy will shoot
@export var can_shoot: bool = false
## The weapon that the enemy will use
@export var weapon: WeaponDetails
## The duration of the shooting
@export var shooting_duration_interval: Vector2 = Vector2.ZERO
## The duration of the cooldown
@export var shooting_cooldown_interval: Vector2 = Vector2.ZERO

@onready var _active_weapon_component: ActiveWeaponComponent = $ShotingMechanics/ActiveWeaponComponent
@onready var _fire_weapon: FireWeaponComponent = $ShotingMechanics/FireWeapon

var _fired_previous_frame: bool = false
var _fire_target: Node2D 
var fire_cooldown_time_reseter: float = 0.0
enum State { COOLDOWN, SHOOTING }
var _state: State = State.COOLDOWN
var _state_timer: Timer

func _ready() -> void:
	super._ready()
	main_event_bus.level_completed.connect(_on_level_completed)
	_fire_target = GameManager.player
	_active_weapon_component.set_weapon(weapon)
	_state_timer = Timer.new()
	add_child(_state_timer)
	_state_timer.timeout.connect(_on_state_timer_timeout)
	_enter_state(State.COOLDOWN)

func _process(delta: float) -> void:
	_fire()
	_processKnockbackTimer(delta)

func _fire() -> void:
	if isReadyToFire():
		_fired_previous_frame = true
		_fire_weapon.fire_weapon.emit(true, _fired_previous_frame, 1.0, _fire_target.global_position)
	else:
		_fired_previous_frame = false
		_fire_weapon.fire_weapon.emit(false, _fired_previous_frame, 1.0, _fire_target.global_position)

func _on_level_completed(_args: MainEventBus.LevelCompletedArgs) -> void:
	_fired_previous_frame = true
	_state_timer.stop()
	can_shoot = false

func _on_state_timer_timeout() -> void:
	if _state == State.SHOOTING:
		_enter_state(State.COOLDOWN)
	else:
		_enter_state(State.SHOOTING)

func _enter_state(new_state: State) -> void:
	_state = new_state
	match _state:
		State.SHOOTING:
			can_shoot = true
			_state_timer.start(_rng.randf_range(shooting_duration_interval.x, shooting_duration_interval.y))
		State.COOLDOWN:
			can_shoot = false
			_state_timer.start(_rng.randf_range(shooting_cooldown_interval.x, shooting_cooldown_interval.y))
	
func isReadyToFire() -> bool:
	return can_shoot and !_fired_previous_frame
