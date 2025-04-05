extends Node2D

@onready var random_drops: RandomDrops = $RandomDrops
@onready var enemies_holder: Node2D = $EnemiesHolder
@onready var _pool_cut_visualizer: PoolFracture = $PoolFractureCutVisualizer
@onready var _pool_fracture_shards: PoolFracture = $PoolFractureShards
@onready var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
@onready var label: Label = $UI/Control/Label

var kill_count: int = 0

func _ready() -> void:
	random_drops.spawn_drops(20)
	await GameManager.init_timer(0.5).timeout
	for enemy in enemies_holder.get_children():
		print(enemy)
		enemy.Damaged.connect(on_enemy_damaged)
		enemy.Fractured.connect(on_enemy_fractured)
		enemy.Died.connect(on_enemy_died)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.is_pressed():
			random_drops.spawn_drops(20)
			
			await GameManager.init_timer(0.5).timeout
			for enemy in enemies_holder.get_children():
				enemy.Damaged.connect(on_enemy_damaged)
				enemy.Fractured.connect(on_enemy_fractured)
				enemy.Died.connect(on_enemy_died)


func spawnShapeVisualizer(cut_pos : Vector2, cut_shape : PackedVector2Array, fade_speed : float) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(cut_pos, fade_speed)
	instance.setPolygon(cut_shape)


func spawnFractureBody(fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	print("fracture_shard: ", instance)
	if not instance:
		return
	
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), _rng.randf_range(2.0, 4.0))
	instance.setPolygon(fracture_shard.centered_shape, color, {})
	instance.setMass(new_mass)
	instance.addForce(dir * fracture_force * p)
	instance.addTorque(_rng.randf_range(-1, 1) * p)


func on_enemy_damaged(enemy: Node2D, pos : Vector2, shape : PackedVector2Array, color : Color, fade_speed : float) -> void:
	spawnShapeVisualizer(pos, shape, fade_speed)

func on_enemy_fractured(enemy: Node2D, fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	spawnFractureBody(fracture_shard, new_mass, color, fracture_force, p)

func on_enemy_died(ref: BaseEnemy, pos: Vector2) -> void:
	kill_count += 1
	label.text = "Enemies Killed: {0}".format([kill_count])
