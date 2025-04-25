class_name ShotingEnemy extends BaseEnemy

@export_category("Shooting")
## If true, the enemy will shoot
@export var can_shoot: bool = false
## The weapon that the enemy will use
@export var weapon: WeaponDetails
## The duration of the shooting
@export var shooting_duration_interval: Vector2 = Vector2.ZERO
## The duration of the cooldown
@export var shooting_cooldown_interval: Vector2 = Vector2.ZERO

@onready var active_weapon_component: ActiveWeaponComponent = $ShotingMechanics/ActiveWeaponComponent
@onready var fire_weapon: FireWeaponComponent = $ShotingMechanics/FireWeapon
@onready var bullet_fire_position: Marker2D = %BulletFirePosition
@onready var shoot_effect_position: Marker2D = %ShootEffectPosition

var _fired_previous_frame: bool = false
var _fire_target: Node2D 
var fire_cooldown_time_reseter: float = 0.0
var shooting_timer: Timer

func _ready() -> void:
	super._ready()
	main_event_bus.level_completed.connect(_on_level_completed)
	_fire_target = GameManager.player
	active_weapon_component.set_weapon(weapon)
	shooting_timer = Timer.new()
	add_child(shooting_timer)
	shooting_timer.timeout.connect(_on_shooting_timer_timeout)
	start_cooldown()

func _process(delta: float) -> void:
	_fire()
	_processKnockbackTimer(delta)

func _fire() -> void:
	if isReadyToFire():
		fire_weapon.fire_weapon.emit(true, _fired_previous_frame, 1.0, _fire_target.global_position)
		_fired_previous_frame = true
	else:
		_fired_previous_frame = false

func _on_level_completed(_args: MainEventBus.LevelCompletedArgs) -> void:
	_fired_previous_frame = true
	shooting_timer.stop()
	can_shoot = false

func _on_shooting_timer_timeout():
	if can_shoot:
		start_cooldown()
	else:
		start_shooting()

func start_shooting():
	can_shoot = true
	shooting_timer.start(_rng.randf_range(shooting_duration_interval.x, shooting_duration_interval.y))

func start_cooldown():
	can_shoot = false
	shooting_timer.start(_rng.randf_range(shooting_cooldown_interval.x, shooting_cooldown_interval.y))
	
func isReadyToFire() -> bool:
	return can_shoot and !_fired_previous_frame

func set_bullet_pools(player_pool: PoolFracture, enemy_pool: PoolFracture) -> void:
	fire_weapon.set_bullet_pools(player_pool, enemy_pool)
