class_name SplitterEnemy extends BaseEnemy
## Weaves side to side on its way to the player. Killed, it bursts into smaller copies that
## scatter outwards before coming back.

@export var split_count: int = 2
@export var mini_enemy_scene: PackedScene
@export var mini_size_scale: float = 0.6
@export var can_split: bool = true
## Side-to-side waves per second.
@export var weave_frequency: float = 0.8
## How hard it swings sideways (0 = straight line).
@export var weave_strength: float = 1.1
## Speed the pieces fly out with when it splits.
@export var split_burst_speed: float = 320.0

var _weave_phase: float = 0.0

func _ready() -> void:
	super._ready()
	_weave_phase = _rng.randf() * TAU

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	_weave_phase += delta * weave_frequency * TAU
	var forward: Vector2 = global_position.direction_to(threat.global_position)
	return (forward + forward.orthogonal() * sin(_weave_phase) * weave_strength).normalized()

func kill(natural_death: bool = false) -> void:
	if can_split and !natural_death and mini_enemy_scene:
		_spawn_mini_enemies()
	super.kill(natural_death)

func _spawn_mini_enemies() -> void:
	for i in range(split_count):
		var mini_enemy = mini_enemy_scene.instantiate()
		if mini_enemy is SplitterEnemy:
			mini_enemy.can_split = false
			# Smaller pieces wiggle faster
			mini_enemy.weave_frequency = weave_frequency * 1.6
		
		var angle = (TAU / split_count) * i
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		spawn_extra_enemy(mini_enemy, global_position + dir * 50.0)
		mini_enemy.scale = Vector2.ONE * mini_size_scale
		
		if mini_enemy.has_method("setPolygon"):
			var scaled_poly = PackedVector2Array()
			for point in start_poly:
				scaled_poly.append(point * mini_size_scale)
			mini_enemy.setPolygon(scaled_poly)
		if mini_enemy is RigidBody2D:
			mini_enemy.linear_velocity = dir * split_burst_speed
