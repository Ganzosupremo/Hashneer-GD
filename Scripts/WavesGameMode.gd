extends Node2D

@onready var random_drops: RandomDrops = $RandomDrops
@onready var enemies_holder: Node2D = %EnemiesHolder
@onready var _pool_cut_visualizer: PoolFracture = $PoolFractureCutVisualizer
@onready var _pool_fracture_shards: PoolFracture = $PoolFractureShards
@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var label: Label = $UI/Control/Label
@onready var boss_timer: Timer = Timer.new()
@onready var boss_progress_bar: ProgressBar = $UI/BossTimer/MarginContainer/BossProgressBar

var time_to_spawn_boss: float = 100.0
var time_to_spawn_boss_passed: float = 0.0
var boss_spawned: bool = false

var kill_count: int = 0
var spawn_enemies_timer: Timer
var _spawn_timer_time: float = 0.0
var _spawn_time: float = 5.0
@export var level_args: LevelBuilderArgs
var spawned_enemies_array: Array = []

func _ready() -> void:
	boss_progress_bar.max_value = time_to_spawn_boss
	spawn_enemies_timer = Timer.new()
	add_child(spawn_enemies_timer)
	spawn_enemies_timer.wait_time = _spawn_time
	spawn_enemies_timer.one_shot = false
	spawn_enemies_timer.timeout.connect(on_spawn_enemies_timer_timeout)
	spawned_enemies_array.append_array(_spawn_enemies(20))
	spawn_enemies_timer.start()

func _process(delta: float) -> void:
	_increase_time_to_spawn_boss(delta)

func _increase_time_to_spawn_boss(delta: float) -> void:
	if boss_spawned == false:
		time_to_spawn_boss_passed += delta
		boss_progress_bar.value = time_to_spawn_boss_passed

func _spawn_enemies(count: int) -> Array[Node]:
	var enemies: Array[Node] = []
	for i in range(count):
		var enemy = random_drops.spawn_drops(1)
		if enemy:
			enemies.append(enemy)
			enemy.Damaged.connect(on_enemy_damaged)
			enemy.Fractured.connect(on_enemy_fractured)
			enemy.Died.connect(on_enemy_died)
			enemy.Freed.connect(on_enemy_freed)
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
	# instance.addTorque(_rng.randf_range(-1, 1))

func on_spawn_enemies_timer_timeout() -> void:
	spawned_enemies_array.append_array(_spawn_enemies(10))
	for enemy in spawned_enemies_array:
		if enemy.is_connected("Damaged", on_enemy_damaged) or \
			enemy.is_connected("Fractured", on_enemy_fractured) or \
			enemy.is_connected("Died", on_enemy_died) or \
			enemy.is_connected("Freed", on_enemy_freed):
				continue

func on_enemy_damaged(enemy: BaseEnemy, pos : Vector2, shape : PackedVector2Array, color : Color, fade_speed : float) -> void:
	spawnShapeVisualizer(pos, shape, color, fade_speed)
	GameManager.player.damage(randf_range(enemy.collision_damage.x, enemy.collision_damage.y) * 1.2)

func on_enemy_fractured(_enemy: BaseEnemy, fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)

func on_enemy_died(_ref: BaseEnemy, _pos: Vector2) -> void:
	spawned_enemies_array.erase(_ref)
	kill_count += 1
	label.text = "Enemies Killed: {0}".format([kill_count])

func on_enemy_freed(ref: BaseEnemy) -> void:
	spawned_enemies_array.erase(ref)

func _on_boss_progress_bar_value_changed(value: float) -> void:
	if value == boss_progress_bar.max_value:
		boss_spawned = true
		print_debug("Boss spawned")
