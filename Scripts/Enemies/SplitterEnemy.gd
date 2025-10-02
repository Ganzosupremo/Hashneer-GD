class_name SplitterEnemy extends BaseEnemy

@export var split_count: int = 2
@export var mini_enemy_scene: PackedScene
@export var mini_size_scale: float = 0.6
@export var can_split: bool = true

func _ready() -> void:
	super._ready()

func kill(natural_death: bool = false) -> void:
	if can_split and !natural_death and mini_enemy_scene:
		_spawn_mini_enemies()
	super.kill(natural_death)

func _spawn_mini_enemies() -> void:
	var enemies_holder = get_tree().get_first_node_in_group("EnemiesHolder")
	if not enemies_holder:
		return
	
	for i in range(split_count):
		var mini_enemy = mini_enemy_scene.instantiate()
		if mini_enemy is SplitterEnemy:
			mini_enemy.can_split = false
		
		enemies_holder.add_child(mini_enemy)
		
		var angle = (TAU / split_count) * i
		var offset = Vector2(cos(angle), sin(angle)) * 50.0
		mini_enemy.global_position = global_position + offset
		mini_enemy.scale = Vector2.ONE * mini_size_scale
		
		if mini_enemy.has_method("setPolygon"):
			var scaled_poly = PackedVector2Array()
			for point in start_poly:
				scaled_poly.append(point * mini_size_scale)
			mini_enemy.setPolygon(scaled_poly)
