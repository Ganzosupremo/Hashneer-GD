extends Node2D

const ENEMY_LIFETIME_SECONDS: float = 60.0
const MAX_DESPAWNS_PER_FRAME: int = 15

@onready var enemies_holder: Node2D = %EnemiesHolder
@onready var _pool_cut_visualizer: PoolFracture = $PoolFractureCutVisualizer
@onready var _pool_fracture_shards: PoolFracture = $PoolFractureShards
@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var label: Label = $UI/Control/Label
@onready var boss_progress_bar: ProgressBar = $UI/BossTimer/MarginContainer/BossProgressBar
@onready var level_completed: LevelCompletedUI = $UI/LevelCompletedUI

@onready var random_drops_holder: Node2D = $RandomDropsHolder
@onready var boss_spawner: RandomDrops = $BossSpawner
@onready var random_drops: RandomDrops = $RandomDropsHolder/RandomDrops
@onready var random_drops_2: RandomDrops = $RandomDropsHolder/RandomDrops2

@onready var player_bullets_pool: PoolFracture = $PlayerBulletsPool
@onready var enemy_bullets_pool: PoolFracture = $EnemyBulletsPool

@export var level_args: LevelBuilderArgs
@export var main_event_bus: MainEventBus
@export var music: MusicDetails
@export var boss_music: MusicDetails

var time_to_spawn_boss: float = 60.0
var time_to_spawn_boss_passed: float = 0.0
var boss_spawned: bool = false

var kill_count: int = 0
var spawn_enemies_timer: Timer
var _spawn_time: float = 15.0
var _spawned_enemies_array: Array = []
var _enemies_to_despawn_queue: Array = [] # Queue for enemies pending despawn

func _ready() -> void:
	AudioManager.change_music_clip(music)
	level_args = GameManager.get_level_args()
	boss_progress_bar.max_value = time_to_spawn_boss
	boss_progress_bar.value = 0.0
#region Enemies Timer
	spawn_enemies_timer = Timer.new()
	add_child(spawn_enemies_timer)
	spawn_enemies_timer.wait_time = _spawn_time
	spawn_enemies_timer.one_shot = false
	spawn_enemies_timer.timeout.connect(on_spawn_enemies_timer_timeout)
	_spawned_enemies_array.append_array(_spawn_enemies(level_args.spawn_count))
	spawn_enemies_timer.start()
#endregion
	
	main_event_bus.emit_bullet_pool_setted(
		{
			"player_pool": player_bullets_pool,
			"enemy_pool": enemy_bullets_pool,
		}
	)
	
	boss_spawner.drops_table = level_args.boss_drop_table
	random_drops.drops_table = level_args.enemies_drop_table
	random_drops_2.drops_table = level_args.enemies_drop_table

func _process(_delta: float) -> void:
	_check_enemy_lifetime()
	_process_despawn_queue()

func _check_enemy_lifetime() -> void:
	var current_time_msec = Time.get_ticks_msec()

	for i in range(_spawned_enemies_array.size() -1, -1, -1):
		var enemy: BaseEnemy = _spawned_enemies_array[i]

		if not is_instance_valid(enemy):
			_spawned_enemies_array.remove_at(i)
			continue
		
		if _enemies_to_despawn_queue.has(enemy):
			continue

		var enemy_spawn_time = enemy.spawn_timestamp
		# Ensure spawn_timestamp is not zero (might happen if _ready hasn't run yet somehow)
		if enemy_spawn_time == 0:
			continue

		var age_seconds = (current_time_msec - enemy_spawn_time) / 1000.0
		if age_seconds > ENEMY_LIFETIME_SECONDS:
			_enemies_to_despawn_queue.append(enemy)
			_spawned_enemies_array.remove_at(i)

func _process_despawn_queue() -> void:
	var despawn_count: int = 0

	while not _enemies_to_despawn_queue.is_empty() and despawn_count < MAX_DESPAWNS_PER_FRAME:
		var enemy_to_despawn: BaseEnemy = _enemies_to_despawn_queue.pop_front()

		enemy_to_despawn.kill(true)
		despawn_count += 1

# func _increase_time_to_spawn_boss(delta: float) -> void:
# 	if boss_spawned == false:
# 		time_to_spawn_boss_passed += delta
# 		boss_progress_bar.value = time_to_spawn_boss_passed

func _spawn_enemies(count: int) -> Array[Node]:
	var enemies: Array[Node] = []
	var spawners : Array = random_drops_holder.get_children()
	
	if spawners.is_empty():
		push_error("WavesGameMode: Random drops holder is empty")
		return enemies

	for i in range(count):
		var random_spawner: RandomDrops = spawners[_rng.randi_range(0, spawners.size() - 1)]
		
		if not random_spawner:
			push_warning("WavesGameMode: Random drops spawner is null")
			continue

		var enemy: BaseEnemy = random_spawner.spawn_drops(1)
		if enemy:
			enemies.append(enemy)
			enemy.drops_count = level_args.enemy_drops_count
			enemy.Damaged.connect(on_enemy_damaged)
			enemy.Fractured.connect(on_enemy_fractured)
			enemy.Died.connect(on_enemy_died)
			# enemy.Freed.connect(on_enemy_freed)
			main_event_bus.emit_bullet_pool_setted(
				{
					"player_pool": player_bullets_pool,
					"enemy_pool": enemy_bullets_pool,
				})
	return enemies

func spawnShapeVisualizer(cut_pos : Vector2, cut_shape : PackedVector2Array, color: Color, fade_speed : float) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(cut_pos, fade_speed)
	instance.setColor(Color(color.r, color.g, color.b, 0.45), Color(color.r, color.g, color.b, 0.45))
	instance.setPolygon(cut_shape)

func spawnFractureBody(fracture_shard : Dictionary, new_mass : float, color : Color, _fracture_force : float, _p : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), _rng.randf_range(1.0, 3.0))
	instance.setPolygon(fracture_shard.centered_shape, color, {})
	instance.setMass(new_mass)
	instance.addForce(dir * _p)

func on_spawn_enemies_timer_timeout() -> void:
	_spawned_enemies_array.append_array(_spawn_enemies(10))

func on_enemy_damaged(enemy: BaseEnemy, pos : Vector2, shape : PackedVector2Array, color : Color, fade_speed : float) -> void:
	spawnShapeVisualizer(pos, shape, color, fade_speed)
	GameManager.player.damage(pow(randf_range(enemy.collision_damage.x, enemy.collision_damage.y), level_args.enemy_damage_multiplier))

func on_enemy_fractured(_enemy: BaseEnemy, fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)

func on_enemy_died(_ref: BaseEnemy, _pos: Vector2, natural_death: bool) -> void:
	_spawned_enemies_array.erase(_ref)
	if !natural_death:
		kill_count += 1
		label.text = "Enemies Killed: {0}".format([kill_count])
		boss_progress_bar.value += 1

func _on_boss_progress_bar_value_changed(value: float) -> void:
	if value == boss_progress_bar.max_value:
		AudioManager.change_music_clip(boss_music)
		boss_spawner.spawn_drops(1)
		boss_spawned = true
		
func _on_exit_button_pressed() -> void:
	GameManager.emit_level_completed(Constants.ERROR_210)
