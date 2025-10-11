class_name WaveSpawner extends Node2D


signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_wave_triggered()
signal enemy_spawned(enemy: BaseEnemy)

@export var enemies_holder: Node2D
@export var spawn_area_rect: Rect2 = Rect2(-100, -100, 2200, 2200)
@export var initial_wave_delay: float = 2.0
@export var wave_completion_delay: float = 3.0

const ENEMY_SCENES = {
	"basic_square": preload("res://Scenes/Enemies/SquareEnemy.tscn"),
	"basic_triangle": preload("res://Scenes/Enemies/TriangleEnemy.tscn"),
	"shooter": preload("res://Scenes/Enemies/ShooterEnemy.tscn"),
	"charger": preload("res://Scenes/Enemies/ChargingEnemy.tscn"),
	"fast_dart": preload("res://Scenes/Enemies/FastDartEnemy.tscn"),
	"tank": preload("res://Scenes/Enemies/TankEnemy.tscn"),
	"exploder": preload("res://Scenes/Enemies/ExplodingEnemy.tscn"),
	"splitter": preload("res://Scenes/Enemies/SplitterEnemy.tscn"),
	"sniper": preload("res://Scenes/Enemies/SniperEnemy.tscn"),
	"teleporter": preload("res://Scenes/Enemies/TeleporterEnemy.tscn"),
	"healer": preload("res://Scenes/Enemies/HealerEnemy.tscn"),
	"spinner": preload("res://Scenes/Enemies/SpinnerEnemy.tscn"),
}

const BOSS_SCENE = preload("res://Scenes/Enemies/SquareBoss.tscn")

var current_wave: int = 0
var enemies_in_wave: int = 0
var enemies_killed_in_wave: int = 0
var enemies_despawned_in_wave: int = 0
var wave_active: bool = false
var wave_timer: Timer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawned_enemies: Array[BaseEnemy] = []

func _ready() -> void:
	_rng.randomize()
	wave_timer = Timer.new()
	add_child(wave_timer)
	wave_timer.one_shot = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	
	await get_tree().create_timer(initial_wave_delay).timeout
	start_next_wave()

func start_next_wave() -> void:
	current_wave += 1
	enemies_killed_in_wave = 0
	enemies_despawned_in_wave = 0
	wave_active = true
	
	var wave_config = _get_wave_configuration(current_wave)
	enemies_in_wave = wave_config.total_count
	
	wave_started.emit(current_wave)
	_spawn_wave(wave_config)

func _get_wave_configuration(wave_num: int) -> Dictionary:
	var config = {
		"total_count": 0,
		"compositions": []
	}
		
	if wave_num <= 2:
		config.compositions = [
			{"type": "basic_square", "count": 150},
			{"type": "basic_triangle", "count": 4},
		]
	elif wave_num <= 5:
		config.compositions = [
			{"type": "basic_square", "count": 5},
			{"type": "shooter", "count": 4},
			{"type": "fast_dart", "count": 3},
			{"type": "charger", "count": 3},
		]
	elif wave_num <= 8:
		config.compositions = [
			{"type": "shooter", "count": 5},
			{"type": "fast_dart", "count": 4},
			{"type": "tank", "count": 3},
			{"type": "exploder", "count": 4},
			{"type": "charger", "count": 4},
		]
	elif wave_num <= 12:
		config.compositions = [
			{"type": "sniper", "count": 4},
			{"type": "teleporter", "count": 3},
			{"type": "tank", "count": 3},
			{"type": "splitter", "count": 3},
			{"type": "healer", "count": 2},
			{"type": "spinner", "count": 3},
			{"type": "fast_dart", "count": 3},
		]
	else:
		var enemy_types = ENEMY_SCENES.keys()
		enemy_types.erase("basic_square")
		enemy_types.erase("basic_triangle")
		
		var base_count = 3 + int(wave_num / 5)
		for enemy_type in enemy_types:
			config.compositions.append({"type": enemy_type, "count": base_count})
	
	for comp in config.compositions:
		config.total_count += comp.count
	
	return config

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

func _complete_wave() -> void:
	wave_active = false
	wave_completed.emit(current_wave)
	
	wave_timer.start(wave_completion_delay)

func _on_wave_timer_timeout() -> void:
	start_next_wave()

func get_wave_info() -> Dictionary:
	return {
		"current_wave": current_wave,
		"enemies_in_wave": enemies_in_wave,
		"enemies_killed": enemies_killed_in_wave,
		"enemies_despawned": enemies_despawned_in_wave,
		"wave_active": wave_active,
		"alive_enemies": _spawned_enemies.size()
	}
