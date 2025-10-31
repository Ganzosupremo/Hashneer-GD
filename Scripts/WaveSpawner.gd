class_name WaveSpawner extends Node2D
## Manages wave-based enemy spawning with support for WavePhase resources.
##
## Wave configurations can be defined in two ways:
## 1. Export WavePhase resources in the editor via the _wave_phases array
## 2. Programmatically by calling set_waves_phases_data() or create_wave_phase()
##
## The system automatically converts between Constants.EnemyType enums and enemy scene string keys.
## If no WavePhase is defined for a wave, it falls back to hardcoded configurations.
##
## Phase System:
## - Phases change every N waves (configurable via waves_per_phase)
## - Each WavePhase resource represents one phase
## - If waves exceed available phases, the last phase is repeated
## - Example: With 3 phases and waves_per_phase=4:
##   Waves 1-4 use Phase 1, Waves 5-8 use Phase 2, Waves 9-12 use Phase 3,
##   Waves 13+ continue using Phase 3


signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal phase_changed(new_phase: int, wave_number: int)  ## Emitted when advancing to a new phase
signal boss_wave_triggered()
signal enemy_spawned(enemy: BaseEnemy)

@export var enemies_holder: Node2D
@export var spawn_area_rect: Rect2 = Rect2(-100, -100, 2200, 2200)
@export var initial_wave_delay: float = 2.0
@export var wave_completion_delay: float = 3.0
## Number of waves before advancing to the next phase
@export var waves_per_phase: int = 4  

const ENEMY_SCENES = {
	"Basic Square": preload("res://Scenes/Enemies/SquareEnemy.tscn"),
	"Basic Triangle": preload("res://Scenes/Enemies/TriangleEnemy.tscn"),
	"Shooter": preload("res://Scenes/Enemies/ShooterEnemy.tscn"),
	"Charger": preload("res://Scenes/Enemies/ChargingEnemy.tscn"),
	"Fast Dart": preload("res://Scenes/Enemies/FastDartEnemy.tscn"),
	"Tank": preload("res://Scenes/Enemies/TankEnemy.tscn"),
	"Exploder": preload("res://Scenes/Enemies/ExplodingEnemy.tscn"),
	"Splitter": preload("res://Scenes/Enemies/SplitterEnemy.tscn"),
	"Sniper": preload("res://Scenes/Enemies/SniperEnemy.tscn"),
	"Teleporter": preload("res://Scenes/Enemies/TeleporterEnemy.tscn"),
	"Healer": preload("res://Scenes/Enemies/HealerEnemy.tscn"),
	"Spinner": preload("res://Scenes/Enemies/SpinnerEnemy.tscn"),
}

const BOSS_SCENE = preload("res://Scenes/Enemies/SquareBoss.tscn")

var current_wave: int = 0
var current_phase: int = 0  ## Tracks the current phase index (0-based)
var enemies_in_wave: int = 0
var enemies_killed_in_wave: int = 0
var enemies_despawned_in_wave: int = 0
var wave_active: bool = false
var wave_timer: Timer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawned_enemies: Array[BaseEnemy] = []
# Define wave configurations using WavePhase resources
var _wave_phases: Array[WavePhase] = []


func _ready() -> void:
	_rng.randomize()
	wave_timer = Timer.new()
	add_child(wave_timer)
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)
		
	await get_tree().create_timer(initial_wave_delay).timeout
	start_next_wave()

#region Public Functions

## Helper function to create a WavePhase resource programmatically.[br]
## This function takes an array of composition data and returns a WavePhase instance.[br]
## The array should contain dictionaries with "enemy_type" (Constants.EnemyType) and "count" (int) keys.[br]
## Example usage:  
## [codeblock]
## create_wave_phase([{enemy_type: Constants.EnemyType.BASIC_SQUARE, count: 5}])
## [/codeblock]
func create_wave_phase(compositions_data: Array) -> WavePhase:
	var phase = WavePhase.new()
	var total: int = 0
	
	for comp_data in compositions_data:
		if comp_data is Dictionary and comp_data.has("enemy_type") and comp_data.has("count"):
			var composition = WaveComposition.new()
			composition.enemy_type = comp_data.enemy_type
			composition.count = comp_data.count
			phase.compositions.append(composition)
			total += comp_data.count
	
	phase.total_count = total
	return phase

func start_next_wave() -> void:
	current_wave += 1
	enemies_killed_in_wave = 0
	enemies_despawned_in_wave = 0
	wave_active = true
	
	# Update current phase based on wave number
	var new_phase: int = _get_phase_index_for_wave(current_wave)
	if new_phase != current_phase and new_phase >= 0:
		current_phase = new_phase
		print("WaveSpawner: Advanced to Phase ", current_phase + 1, " (Wave ", current_wave, ")")
		phase_changed.emit(current_phase, current_wave)
	
	var wave_config = _get_wave_configuration(current_wave)
	enemies_in_wave = wave_config.total_count
	
	wave_started.emit(current_wave)
	_spawn_wave(wave_config)

func spawn_boss() -> BaseEnemy:
	var boss = BOSS_SCENE.instantiate() as BaseEnemy
	
	if not boss:
		push_error("WaveSpawner: Failed to instantiate boss")
		return null
	
	var center_pos = spawn_area_rect.get_center()
	var offset = Vector2(_rng.randf_range(-200, 200), _rng.randf_range(-200, 200))
	boss.global_position = center_pos + offset
	
	if enemies_holder:
		enemies_holder.add_child(boss)
	else:
		add_child(boss)
	
	boss_wave_triggered.emit()
	
	return boss

#endregion

#region Internal Functions

func _get_wave_configuration(wave_num: int) -> Dictionary:
	var config = {
		"total_count": 0,
		"compositions": []
	}
	
	# First, check if we have WavePhase resources defined
	if not _wave_phases.is_empty():
		var phase_index: int = _get_phase_index_for_wave(wave_num)
		
		if phase_index >= 0 and phase_index < _wave_phases.size():
			var wave_phase: WavePhase = _wave_phases[phase_index]
			
			if wave_phase and wave_phase.compositions.size() > 0:
				# Convert WaveComposition resources to the dictionary format
				for composition in wave_phase.compositions:
					var enemy_string: String = Utils.enum_label(Constants.EnemyType, composition.enemy_type)
					if enemy_string != "":
						config.compositions.append({
							"type": enemy_string,
							"count": composition.count
						})
				
				# Calculate or use the total count from the phase
				if wave_phase.total_count > 0:
					config.total_count = wave_phase.total_count
				else:
					# Calculate total if not set
					for comp in config.compositions:
						config.total_count += comp.count
				
				return config
	
	# Fallback to hardcoded configurations if no WavePhase is defined
	if wave_num <= 2:
		config.compositions = [
			{"type": "Basic Square", "count": 150},
			{"type": "Basic Triangle", "count": 4},
		]
	elif wave_num <= 5:
		config.compositions = [
			{"type": "Basic Square", "count": 5},
			{"type": "Shooter", "count": 4},
			{"type": "Fast Dart", "count": 3},
			{"type": "Charger", "count": 3},
		]
	elif wave_num <= 8:
		config.compositions = [
			{"type": "Shooter", "count": 5},
			{"type": "Fast Dart", "count": 4},
			{"type": "Tank", "count": 3},
			{"type": "Exploder", "count": 4},
			{"type": "Charger", "count": 4},
		]
	elif wave_num <= 12:
		config.compositions = [
			{"type": "Sniper", "count": 4},
			{"type": "Teleporter", "count": 3},
			{"type": "Tank", "count": 3},
			{"type": "Splitter", "count": 3},
			{"type": "Healer", "count": 2},
			{"type": "Spinner", "count": 3},
			{"type": "Fast Dart", "count": 3},
		]
	else:
		var enemy_types = ENEMY_SCENES.keys()
		enemy_types.erase("Basic Square")
		enemy_types.erase("Basic Triangle")
		
		var base_count: int = 3 + int(wave_num / 5)
		for enemy_type in enemy_types:
			config.compositions.append({"type": enemy_type, "count": base_count})
	
	for comp in config.compositions:
		config.total_count += comp.count
	
	return config

## Calculates which phase index to use based on the current wave number.[br]
## Returns the phase index (0-based). If the wave exceeds available phases,
## returns the last phase index to keep using it.
func _get_phase_index_for_wave(wave_num: int) -> int:
	if _wave_phases.is_empty():
		return -1  # No phases defined
	
	# Calculate which phase this wave belongs to (0-based)
	var calculated_phase: int = (wave_num - 1) / waves_per_phase
	
	# Clamp to the last available phase if we've run out
	var max_phase_index: int = _wave_phases.size() - 1
	return min(calculated_phase, max_phase_index)

func _spawn_wave(wave_config: Dictionary) -> void:
	for composition in wave_config.compositions:
		for i in range(composition.count):
			await get_tree().create_timer(0.15).timeout
			_spawn_enemy(composition.type)

func _spawn_enemy(enemy_type: String) -> BaseEnemy:
	if not ENEMY_SCENES.has(enemy_type):
		push_error("WaveSpawner: Unknown enemy type: " + enemy_type)
		return null
		
	var enemy_scene = ENEMY_SCENES[enemy_type]
	var enemy = enemy_scene.instantiate() as BaseEnemy
		
	if not enemy:
		push_error("WaveSpawner: Failed to instantiate enemy: " + enemy_type)
		return null
		
	var spawn_pos: Vector2 = _get_spawn_position()
	enemy.global_position = spawn_pos
		
	if enemies_holder:
		enemies_holder.add_child(enemy)
	else:
		add_child(enemy)
		
	enemy.Died.connect(_on_enemy_died.bind(enemy))
	_spawned_enemies.append(enemy)
	enemy_spawned.emit(enemy)
	
	return enemy

func _complete_wave() -> void:
	wave_active = false
	wave_completed.emit(current_wave)
	
	wave_timer.start(wave_completion_delay)

func _get_spawn_position() -> Vector2:
	var spawn_edge = _rng.randi_range(0, 3)
	var pos = Vector2.ZERO
	
	match spawn_edge:
		0:
			pos = Vector2(
				_rng.randf_range(spawn_area_rect.position.x, spawn_area_rect.position.x + spawn_area_rect.size.x),
				spawn_area_rect.position.y
			)
		1:
			pos = Vector2(
				spawn_area_rect.position.x + spawn_area_rect.size.x,
				_rng.randf_range(spawn_area_rect.position.y, spawn_area_rect.position.y + spawn_area_rect.size.y)
			)
		2:
			pos = Vector2(
				_rng.randf_range(spawn_area_rect.position.x, spawn_area_rect.position.x + spawn_area_rect.size.x),
				spawn_area_rect.position.y + spawn_area_rect.size.y
			)
		3:
			pos = Vector2(
				spawn_area_rect.position.x,
				_rng.randf_range(spawn_area_rect.position.y, spawn_area_rect.position.y + spawn_area_rect.size.y)
			)
	
	return pos

#endregion

#region Signal Functions

func _on_enemy_died(_ref: BaseEnemy, _pos: Vector2, natural_death: bool, enemy: BaseEnemy) -> void:
	_spawned_enemies.erase(enemy)
	if !wave_active: return
	
	if natural_death:
		enemies_despawned_in_wave += 1
	else:
		enemies_killed_in_wave += 1
	
	var total_removed: int = enemies_despawned_in_wave + enemies_killed_in_wave
	
	if total_removed >= enemies_in_wave:
		_complete_wave()

func _on_wave_timer_timeout() -> void:
	start_next_wave()

#endregion

#region Setters

func set_wave_spawner(params: Dictionary) -> void:
	if params.has("waves_per_phase"):
		waves_per_phase = params["waves_per_phase"]
	if params.has("initial_wave_delay"):
		initial_wave_delay = params["wave_spawn_time"]
	if params.has("wave_data"):
		set_waves_phases_data(params["wave_data"])

## Sets the wave phases data programmatically.
func set_waves_phases_data(wave_data: Array[WavePhase]) -> void:
	_wave_phases = wave_data.duplicate(true)

#endregion

#region Getters

func get_wave_info() -> Dictionary:
	return {
		"current_wave": current_wave,
		"current_phase": current_phase,
		"total_phases": _wave_phases.size(),
		"waves_per_phase": waves_per_phase,
		"enemies_in_wave": enemies_in_wave,
		"enemies_killed": enemies_killed_in_wave,
		"enemies_despawned": enemies_despawned_in_wave,
		"wave_active": wave_active,
		"alive_enemies": _spawned_enemies.size()
	}

## Gets the total number of phases defined
func get_total_phases() -> int:
	return _wave_phases.size()

## Gets the current phase index (0-based)
func get_current_phase() -> int:
	return current_phase

## Checks if we're on the last phase
func is_last_phase() -> bool:
	return current_phase >= _wave_phases.size() - 1

#endregion
