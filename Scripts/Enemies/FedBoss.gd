class_name FedBoss extends ShooterEnemy
## "La FED": slow boss that fights in three phases depending on its remaining health.[br]
## Phase 1: fires rings of bullets.[br]
## Phase 2: keeps firing rings and starts printing money (minions).[br]
## Phase 3: fires bullet spirals much faster.

signal phase_changed(new_phase: int)

@export_category("FED Boss")
## Weapon used in phase 3. Phases 1 and 2 use [member ShooterEnemy.weapon].
@export var final_phase_weapon: WeaponDetails
## Seconds between volleys for phases 1, 2 and 3.
@export var volley_interval_per_phase: Array[float] = [2.8, 2.2, 1.2]
## Health percent below which each next phase starts.
@export var phase_thresholds: Vector2 = Vector2(0.66, 0.33)
@export var minion_scene: PackedScene
@export var print_interval: float = 6.0
@export var minions_per_print: int = 2
@export var max_alive_minions: int = 6

var _phase: int = 1
var _volley_timer: float = 1.5
var _print_timer: float = 0.0
var _minions: Array[BaseEnemy] = []

func _process(delta: float) -> void:
	_processKnockbackTimer(delta)
	if isDead() or is_player_dead or !can_shoot:
		return
	_update_phase()

	_volley_timer -= delta
	if _volley_timer <= 0.0:
		_volley_timer = volley_interval_per_phase[clampi(_phase - 1, 0, volley_interval_per_phase.size() - 1)]
		_fire_weapon.fire_weapon.emit(true, false, 1.0, _fire_target.global_position)
	else:
		_fire_weapon.fire_weapon.emit(false, true, 1.0, _fire_target.global_position)

	if _phase >= 2 and minion_scene:
		_print_timer -= delta
		if _print_timer <= 0.0:
			_print_timer = print_interval
			_print_minions()

# Shooting is driven by the volley timer, not the shooter's shooting/cooldown states.
func _enter_state(_new_state: State) -> void:
	can_shoot = true

func _update_phase() -> void:
	var health: float = getHealthPercent()
	var new_phase: int = 1
	if health <= phase_thresholds.y:
		new_phase = 3
	elif health <= phase_thresholds.x:
		new_phase = 2
	if new_phase <= _phase:
		return
	_phase = new_phase
	if _phase == 3 and final_phase_weapon:
		_active_weapon_component.set_weapon(final_phase_weapon)
	_volley_timer = 0.6
	phase_changed.emit(_phase)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.8, 0.6, 0.6), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
	if GameManager.get_main_camera():
		GameManager.get_main_camera().shake_with_preset(Constants.ShakeMagnitude.Medium)

func _print_minions() -> void:
	_minions = _minions.filter(func(m): return is_instance_valid(m) and !m.isDead())
	for i in range(mini(minions_per_print, max_alive_minions - _minions.size())):
		var minion: BaseEnemy = minion_scene.instantiate()
		var offset: Vector2 = Vector2.RIGHT.rotated(_rng.randf() * TAU) * 120.0
		spawn_extra_enemy(minion, global_position + offset)
		_minions.append(minion)

func kill(natural_death: bool = false) -> void:
	Died.emit(self, position, natural_death)
	hide()
	if !natural_death:
		random_drops.spawn_drops(1)
		AudioManager.create_2d_audio_at_location(position, sound_on_dead.sound_type, sound_on_dead.destination_audio_bus)
	queue_free()
