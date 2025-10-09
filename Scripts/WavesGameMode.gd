extends Node2D

const ENEMY_LIFETIME_SECONDS: float = 120.0
const MAX_DESPAWNS_PER_FRAME: int = 15
const MAX_ACTIVE_ENEMIES: int = 150

const WAVE_SPAWNER = preload("res://Scenes/GameModes/WaveSpawner.tscn")
@onready var enemies_holder: Node2D = %EnemiesHolder
@onready var _pool_cut_visualizer: PoolFracture = $PoolFractureCutVisualizer
@onready var _pool_fracture_shards: PoolFracture = $PoolFractureShards
@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var enemies_killed_label: Label = %EnemiesKilledLabel
@onready var wave_label: Label = %WaveLabel
@onready var boss_progress_bar: ProgressBar = %BossProgressBar
@onready var level_completed: LevelCompletedUI = %LevelCompletedUI

@onready var player_bullets_pool: PoolFracture = %PlayerBulletsPool
@onready var enemy_bullets_pool: PoolFracture = %EnemyBulletsPool

@export var level_args: LevelBuilderArgs
@export var main_event_bus: MainEventBus
@export var music: MusicDetails
@export var boss_music: MusicDetails
@export var boss_kill_threshold_increment: int = 50
@export var item_drops_bus: ItemDropsBus

var wave_spawner: Node2D
var kill_count: int = 0
var despawn_count: int = 0
var _spawned_enemies_array: Array = []
var _enemies_to_despawn_queue: Array = []

var boss_tracker = {
        "current_boss_number": 0,
        "base_threshold": 0,
        "kills_for_next_boss": 0,
        "total_bosses_spawned": 0,
        "boss_active": false,
        "bitcoin_spawned": false,
        "checking_drops": false
}

var bitcoin_check_timer: Timer
var current_boss: BaseEnemy = null

func _ready() -> void:
        AudioManager.change_music_clip(music)
        level_args = GameManager.get_level_args()

        boss_tracker.base_threshold = level_args.kills_to_spawn_boss
        boss_tracker.kills_for_next_boss = level_args.kills_to_spawn_boss
        boss_tracker.current_boss_number = 1
        
        boss_progress_bar.max_value = boss_tracker.kills_for_next_boss
        boss_progress_bar.value = 0.0

        bitcoin_check_timer = Timer.new()
        bitcoin_check_timer.one_shot = true
        bitcoin_check_timer.timeout.connect(_on_bitcoin_check_timeout)
        add_child(bitcoin_check_timer)

        if item_drops_bus:
                item_drops_bus.item_picked.connect(_on_item_picked)

        _setup_wave_spawner()

func _setup_wave_spawner() -> void:
        wave_spawner = WAVE_SPAWNER.instantiate()
        add_child(wave_spawner)
        wave_spawner.enemies_holder = enemies_holder
        wave_spawner.spawn_area_rect = Rect2(-100, -100, 2200, 2200)
        
        wave_spawner.wave_started.connect(_on_wave_started)
        wave_spawner.wave_completed.connect(_on_wave_completed)
        wave_spawner.enemy_spawned.connect(_connect_enemy_signals)

func _process(_delta: float) -> void:
        _check_enemy_lifetime()
        _check_enemy_cap()
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
				if enemy_spawn_time == 0:
						continue

				var age_seconds = (current_time_msec - enemy_spawn_time) / 1000.0
				if age_seconds > ENEMY_LIFETIME_SECONDS:
						_enemies_to_despawn_queue.append(enemy)
						_spawned_enemies_array.remove_at(i)

func _check_enemy_cap() -> void:
        if _spawned_enemies_array.size() <= MAX_ACTIVE_ENEMIES:
                return
        
        var player = GameManager.player
        if not player:
                return
        
        var player_pos = player.global_position
        var enemies_over_cap = _spawned_enemies_array.size() - MAX_ACTIVE_ENEMIES
        
        var enemies_with_distance = []
        for enemy in _spawned_enemies_array:
                if not is_instance_valid(enemy) or _enemies_to_despawn_queue.has(enemy):
                        continue
                
                var distance = enemy.global_position.distance_squared_to(player_pos)
                enemies_with_distance.append({"enemy": enemy, "distance": distance})
        
        enemies_with_distance.sort_custom(func(a, b): return a.distance > b.distance)
        
        for i in range(min(enemies_over_cap, enemies_with_distance.size())):
                var enemy = enemies_with_distance[i].enemy
                if not _enemies_to_despawn_queue.has(enemy):
                        _enemies_to_despawn_queue.append(enemy)
                        _spawned_enemies_array.erase(enemy)

func _process_despawn_queue() -> void:
		var despawn_count: int = 0

		while not _enemies_to_despawn_queue.is_empty() and despawn_count < MAX_DESPAWNS_PER_FRAME:
				var enemy_to_despawn: BaseEnemy = _enemies_to_despawn_queue.pop_front()
				enemy_to_despawn.kill(true)
				despawn_count += 1

func _on_wave_started(wave_number: int) -> void:
		wave_label.text = "Wave: {0}".format([wave_number])

func _on_wave_completed(wave_number: int) -> void:
		print("Wave {0} completed!".format([wave_number]))

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

func _connect_enemy_signals(enemy: BaseEnemy) -> void:
		if not enemy:
				return
		
		enemy.drops_count = level_args.enemy_drops_count
		enemy.Damaged.connect(on_enemy_damaged)
		enemy.Fractured.connect(on_enemy_fractured)
		enemy.Died.connect(on_enemy_died)
		
		if enemy.shield:
				enemy.shield.fractured.connect(_on_enemy_shield_fractured)
		
		_spawned_enemies_array.append(enemy)

func on_enemy_damaged(enemy: BaseEnemy, pos : Vector2, shape : PackedVector2Array, color : Color, fade_speed : float) -> void:
		spawnShapeVisualizer(pos, shape, color, fade_speed)
		var base_dmg: float = randf_range(enemy.collision_damage.x, enemy.collision_damage.y)
		var scaled: float = base_dmg * level_args.enemy_damage_multiplier
		GameManager.player.damage(scaled, enemy.global_position)

func on_enemy_fractured(_enemy: BaseEnemy, fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
		spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)

func _on_enemy_shield_fractured(_ref: ShieldComponent, fracture_shard: Dictionary, new_mass: float, color: Color, fracture_force: float, p: float) -> void:
		spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)

func on_enemy_died(_ref: BaseEnemy, _pos: Vector2, natural_death: bool) -> void:
        _spawned_enemies_array.erase(_ref)
        
        if not natural_death:
                kill_count += 1
                enemies_killed_label.text = "Enemies Killed: {0}".format([kill_count])
                boss_progress_bar.value = kill_count

                if kill_count >= level_args.kills_to_spawn_boss and not boss_spawned:
                        _spawn_boss()


func _on_boss_progress_bar_value_changed(value: float) -> void:
        if value >= boss_progress_bar.max_value and not boss_spawned:
                _spawn_boss()
				
        _spawned_enemies_array.erase(_ref)
        
        if natural_death:
                despawn_count += 1
        else:
                kill_count += 1
                enemies_killed_label.text = "Enemies Killed: {0}".format([kill_count])
                boss_progress_bar.value = kill_count

                if kill_count >= boss_tracker.kills_for_next_boss and not boss_tracker.boss_active:
                        _spawn_boss()

func _spawn_boss() -> void:
        boss_tracker.boss_active = true
        boss_tracker.total_bosses_spawned += 1
        AudioManager.change_music_clip(boss_music)
        
        print("Spawning Boss #%d at %d kills" % [boss_tracker.current_boss_number, kill_count])
        
        current_boss = wave_spawner.spawn_boss()
        if current_boss:
                _connect_enemy_signals(current_boss)
                current_boss.Died.connect(_on_boss_died)
                
                if current_boss.random_drops and current_boss.random_drops.scene_spawner:
                        current_boss.random_drops.scene_spawner.spawned.connect(_on_boss_item_spawned)

func _on_boss_died(_ref: BaseEnemy, _pos: Vector2, natural_death: bool) -> void:
        if natural_death:
                return
        
        boss_tracker.boss_active = false
        boss_tracker.bitcoin_spawned = false
        boss_tracker.checking_drops = true
        AudioManager.change_music_clip(music)
        
        print("Boss #%d defeated! Waiting 2 seconds to check for Bitcoin drops..." % boss_tracker.current_boss_number)
        bitcoin_check_timer.start(2.0)

func _on_boss_item_spawned(event: SpawnEvent) -> void:
        if not boss_tracker.checking_drops:
                return
        
        var spawned_node = event.instance
        if spawned_node and spawned_node.has_node("Pickup2D"):
                var pickup = spawned_node.get_node("Pickup2D") as Pickup2D
                if pickup:
                        var resource = pickup.get_pickup_resource()
                        if resource is CurrencyPickupResource and resource.currency_type == Constants.CurrencyType.BITCOIN:
                                print("Bitcoin spawned from boss!")
                                boss_tracker.bitcoin_spawned = true

func _on_item_picked(event: PickupEvent) -> void:
        var pickup = event.pickup
        if not pickup:
                return
        
        var resource = pickup.get_pickup_resource()
        if resource is CurrencyPickupResource:
                if resource.currency_type == Constants.CurrencyType.BITCOIN:
                        print("Bitcoin picked up! Level completed!")
                        boss_tracker.checking_drops = false
                        bitcoin_check_timer.stop()
                        _complete_level()

func _on_bitcoin_check_timeout() -> void:
        if not boss_tracker.checking_drops:
                return
        
        boss_tracker.checking_drops = false
        
        if not boss_tracker.bitcoin_spawned:
                print("Boss defeated but no Bitcoin dropped. Escalating threshold...")
                _escalate_boss_threshold()
        else:
                print("Bitcoin dropped by boss. Waiting for player to collect it...")

func _complete_level() -> void:
        print("=== LEVEL COMPLETED ===")
        print("Total Kills: %d" % kill_count)
        print("Total Bosses Defeated: %d" % boss_tracker.total_bosses_spawned)
        print("Enemies Despawned: %d" % despawn_count)
        level_completed.show_with_data(kill_count, 0, 0)

func _escalate_boss_threshold() -> void:
        kill_count = 0
        boss_tracker.current_boss_number += 1
        boss_tracker.kills_for_next_boss = boss_tracker.base_threshold + (boss_tracker.current_boss_number - 1) * boss_kill_threshold_increment
        
        boss_progress_bar.max_value = boss_tracker.kills_for_next_boss
        boss_progress_bar.value = 0
        enemies_killed_label.text = "Enemies Killed: 0"
        
        print("Next boss (#%d) will spawn at %d kills" % [boss_tracker.current_boss_number, boss_tracker.kills_for_next_boss])

func _on_boss_progress_bar_value_changed(value: float) -> void:
        if value >= boss_progress_bar.max_value and not boss_tracker.boss_active:
                _spawn_boss()
                
func _on_exit_button_pressed() -> void:
		GameManager.emit_level_completed(Constants.ERROR_210)
