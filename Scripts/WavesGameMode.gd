extends Node2D

const ENEMY_LIFETIME_SECONDS: float = 120.0
const MAX_DESPAWNS_PER_FRAME: int = 15
const MAX_ACTIVE_ENEMIES: int = 250
const WAVE_SPAWNER = preload("res://Scenes/GameModes/WaveSpawner.tscn")

@onready var _enemies_holder: Node2D = %EnemiesHolder
@onready var _pool_cut_visualizer: PoolFracture = $PoolFractureCutVisualizer
@onready var _pool_fracture_shards: PoolFracture = $PoolFractureShards
@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var _enemies_killed_label: Label = %EnemiesKilledLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _boss_progress_bar: ProgressBar = %BossProgressBar
@onready var _wave_completed_label: Label = %WaveCompletedLabel

## Level Configuration Arguments
@export var level_args: LevelBuilderArgs
## Main event bus for the game mode to emit signals on
@export var main_event_bus: MainEventBus
## Music to play during normal waves
@export var music: MusicDetails
## Music to play during boss waves
@export var boss_music: MusicDetails
## Number of additional kills required for each subsequent boss after the first
@export var boss_kill_threshold_increment: int = 50
## The ItemDropsBus resource that will be used to listen for item spawn and pickup events
@export var item_drops_bus: ItemDropsBus

var _wave_spawner  # Type: WaveSpawner (type hint removed due to Godot loading order)
var _kill_count: int = 0
var _despawn_count: int = 0
var _spawned_enemies_array: Array = []
var _enemies_to_despawn_queue: Array = []

var _boss_tracker = {
                "current_boss_number": 0,
                "base_threshold": 0,
                "kills_for_next_boss": 0,
                "total_bosses_spawned": 0,
                "boss_active": false,
                "bitcoin_spawned": false,
                "checking_drops": false
}

var _bitcoin_check_timer: Timer
var _current_boss: BaseEnemy = null

func _ready() -> void:
                AudioManager.change_music_clip(music)
                level_args = GameManager.get_level_args()

                _boss_tracker.base_threshold = level_args.kills_to_spawn_boss
                _boss_tracker.kills_for_next_boss = level_args.kills_to_spawn_boss
                _boss_tracker.current_boss_number = 1
                                
                _boss_progress_bar.max_value = _boss_tracker.kills_for_next_boss
                _boss_progress_bar.value = 0.0

                _bitcoin_check_timer = Timer.new()
                _bitcoin_check_timer.one_shot = true
                # _bitcoin_check_timer.timeout.connect(_on_bitcoin_check_timeout)
                add_child(_bitcoin_check_timer)


                _wave_completed_label.modulate.a = 0.0
                _wave_completed_label.visible = false

                item_drops_bus.item_picked.connect(_on_item_picked)
                item_drops_bus.item_spawned.connect(_on_boss_item_spawned)

                _setup_navigation_region()
                _setup_wave_spawner()

func _setup_navigation_region() -> void:
                var nav_region = NavigationRegion2D.new()
                nav_region.name = "NavigationRegion"
                add_child(nav_region)
                
                var nav_poly = NavigationPolygon.new()
                var spawn_rect = Rect2(-100, -100, 2200, 2200)
                var padding = 100.0
                
                var outline = PackedVector2Array([
                                Vector2(spawn_rect.position.x - padding, spawn_rect.position.y - padding),
                                Vector2(spawn_rect.end.x + padding, spawn_rect.position.y - padding),
                                Vector2(spawn_rect.end.x + padding, spawn_rect.end.y + padding),
                                Vector2(spawn_rect.position.x - padding, spawn_rect.end.y + padding)
                ])
                
                nav_poly.add_outline(outline)
                nav_poly.make_polygons_from_outlines()
                nav_poly.agent_radius = 20.0
                
                nav_region.navigation_polygon = nav_poly
                nav_region.enabled = true

func _setup_wave_spawner() -> void:
                _wave_spawner = WAVE_SPAWNER.instantiate()
                add_child(_wave_spawner)
                _wave_spawner.enemies_holder = _enemies_holder
                _wave_spawner.spawn_area_rect = Rect2(-100, -100, 2200, 2200)
                                
                _wave_spawner.wave_started.connect(_on_wave_started)
                _wave_spawner.wave_completed.connect(_on_wave_completed)
                _wave_spawner.enemy_spawned.connect(_connect_enemy_signals)

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
                                
                var player = GameManager.get_player()
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
                                
                enemies_with_distance.sort_custom(func(a, b): return a["distance"] > b["distance"])
                                
                for i in range(min(enemies_over_cap, enemies_with_distance.size())):
                                var enemy = enemies_with_distance[i]["enemy"]
                                if not _enemies_to_despawn_queue.has(enemy):
                                                _enemies_to_despawn_queue.append(enemy)
                                                _spawned_enemies_array.erase(enemy)

func _process_despawn_queue() -> void:
                while not _enemies_to_despawn_queue.is_empty() and _despawn_count < MAX_DESPAWNS_PER_FRAME:
                                var enemy_to_despawn: BaseEnemy = _enemies_to_despawn_queue.pop_front()
                                enemy_to_despawn.kill(true)
                                _despawn_count += 1

func _on_wave_started(wave_number: int) -> void:
                if _boss_tracker.boss_active:
                                _wave_label.text = "Boss #{0} Active | Wave: {1}".format([_boss_tracker.current_boss_number, wave_number])
                else:
                                _wave_label.text = "Wave: {0} | Next Boss: #{1} at {2} kills".format([wave_number, _boss_tracker.current_boss_number, _boss_tracker.kills_for_next_boss])

                                _wave_completed_label.visible = true
                                _wave_completed_label.text = "Wave {0} Started!".format([wave_number])

                                await _tween_object(_wave_completed_label, "modulate:a", 0.0, 1.0, 0.5)

                                await get_tree().create_timer(1.0).timeout

                                await _tween_object(_wave_completed_label, "modulate:a", 1.0, 0.0, 0.5)
                                _wave_completed_label.visible = false

func _on_wave_completed(wave_number: int) -> void:
                _wave_completed_label.visible = true
                _wave_completed_label.text = "Wave {0} Completed!".format([wave_number])
                await _tween_object(_wave_completed_label, "modulate:a", 0.0, 1.0, 0.5)

                await get_tree().create_timer(1.0).timeout

                await _tween_object(_wave_completed_label, "modulate:a", 1.0, 0.0, 0.5)
                _wave_completed_label.visible = false

func _tween_object(object: Object, property: String, initial_value, final_value, duration: float) -> void:
                var tween = create_tween()
                object.visible = true
                tween.tween_property(object, property, final_value, duration).from(initial_value).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)

                await tween.finished

func spawnShapeVisualizer(cut_pos : Vector2, cut_shape : PackedVector2Array, color : Color, fade_speed : float) -> void:
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
                GameManager.get_player().damage(scaled, enemy.global_position)

func on_enemy_fractured(_enemy: BaseEnemy, fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
                spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)

func _on_enemy_shield_fractured(_ref: ShieldComponent, fracture_shard: Dictionary, new_mass: float, color: Color, fracture_force: float, p: float) -> void:
                spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)

func on_enemy_died(ref: BaseEnemy, _pos: Vector2, system_despawn: bool) -> void:
                _spawned_enemies_array.erase(ref)

                if system_despawn:
                                _despawn_count += 1
                                _update_kill_display()
                else:
                                _kill_count += 1
                                _update_kill_display()
                                _boss_progress_bar.value = _kill_count

                                if _kill_count >= _boss_tracker.kills_for_next_boss and not _boss_tracker.boss_active:
                                                _spawn_boss()

func _update_kill_display() -> void:
                _enemies_killed_label.text = "Kills: {0}/{1} | Despawned: {2}".format([
                                _kill_count,
                                _boss_tracker.kills_for_next_boss,
                                _despawn_count
                ])

func _spawn_boss() -> void:
                _boss_tracker.boss_active = true
                _boss_tracker.total_bosses_spawned += 1
                AudioManager.change_music_clip(boss_music)
                                
                print("Spawning Boss #%d at %d kills" % [_boss_tracker.current_boss_number, _kill_count])
                _wave_label.text = "Boss #{0} Active!".format([_boss_tracker.current_boss_number])
                                
                _current_boss = _wave_spawner.spawn_boss()
                if _current_boss:
                                _connect_enemy_signals(_current_boss)
                                _current_boss.Died.connect(_on_boss_died)

func _on_boss_died(_ref: BaseEnemy, _pos: Vector2, system_despawn: bool = false) -> void:
                if system_despawn:
                                return
                
                print("_on_boss_died called")
                _boss_tracker.boss_active = false
                _boss_tracker.bitcoin_spawned = false
                _boss_tracker.checking_drops = true
                AudioManager.change_music_clip(music)
                                
                print("Boss #%d defeated!" % _boss_tracker.current_boss_number)
                _bitcoin_check_timer.start(3.0)

func _on_boss_item_spawned(event: SpawnEvent) -> void:
                print("_on_boss_item_spawned called")
                if !_boss_tracker.checking_drops:
                                print("Not checking drops, ignoring.")
                                return
                                
                var spawned_node = event.spawned
                if spawned_node and spawned_node.has_node("Pickup2D"):
                                var pickup = spawned_node.get_node("Pickup2D") as Pickup2D
                                if !pickup: return

                                var resource = pickup.get_pickup_resource()
                                if resource is CurrencyPickupResource and resource.currency_type == Constants.CurrencyType.BITCOIN:
                                                print("Bitcoin spawned from boss!")
                                                _boss_tracker.bitcoin_spawned = true
                                else:
                                                print("Non-Bitcoin item spawned from boss.")
                                                _escalate_boss_threshold()
                                                _boss_tracker.checking_drops = false
                else:
                                print("Spawned node has no Pickup2D component. ", spawned_node)
                                _boss_tracker.checking_drops = false

func _on_item_picked(event: PickupEvent) -> void:
                var pickup = event.pickup
                if !pickup: return

                var resource = pickup.get_pickup_resource()
                if resource is CurrencyPickupResource and resource.currency_type == Constants.CurrencyType.BITCOIN:
                                print("Bitcoin picked up! Level completed!")
                                _boss_tracker.checking_drops = false
                                # _complete_level()

func _on_bitcoin_check_timeout() -> void:
                if not _boss_tracker.checking_drops:
                                return
                                
                _boss_tracker.checking_drops = false
                                
                if not _boss_tracker.bitcoin_spawned:
                                print("Boss defeated but no Bitcoin dropped. Escalating threshold...")
                                _escalate_boss_threshold()
                else:
                                print("Bitcoin dropped by boss. Waiting for player to collect it...")

func _complete_level() -> void:
                print("=== LEVEL COMPLETED ===")
                print("Total Kills: %d" % _kill_count)
                print("Total Bosses Defeated: %d" % _boss_tracker.total_bosses_spawned)
                print("Enemies Despawned: %d" % _despawn_count)
                var code: String = Constants.ERROR_200
                if GameManager.player_in_completed_level(GameManager.get_current_level()):
                                code = Constants.ERROR_500
                GameManager.complete_level(code)

func _escalate_boss_threshold() -> void:
                _kill_count = 0
                _boss_tracker.current_boss_number += 1
                _boss_tracker.kills_for_next_boss = _boss_tracker.base_threshold + (_boss_tracker.current_boss_number - 1) * boss_kill_threshold_increment
                                
                _boss_progress_bar.max_value = _boss_tracker.kills_for_next_boss
                _boss_progress_bar.value = 0
                _update_kill_display()
                _wave_label.text = "Next Boss: #{0} at {1} kills".format([_boss_tracker.current_boss_number, _boss_tracker.kills_for_next_boss])
                                
                print("Next boss (#%d) will spawn at %d kills" % [_boss_tracker.current_boss_number, _boss_tracker.kills_for_next_boss])

func _on_boss_progress_bar_value_changed(value: float) -> void:
                if value >= _boss_progress_bar.max_value and not _boss_tracker.boss_active:
                                _spawn_boss()
                                                                
func _on_exit_button_pressed() -> void:
                GameManager.emit_level_completed(Constants.ERROR_210)
