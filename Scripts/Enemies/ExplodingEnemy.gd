class_name ExplodingEnemy extends BaseEnemy

@export var explosion_radius: float = 150.0
@export var explosion_damage_range: Vector2 = Vector2(30.0, 50.0)
@export var explosion_color: Color = Color(1.0, 0.5, 0.0)
@export var pulse_speed: float = 3.0

var _pulse_time: float = 0.0

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	_pulse_time += delta * pulse_speed
	var pulse = (sin(_pulse_time) + 1.0) * 0.5
	var current_color = color_default.lerp(explosion_color, pulse * 0.5)
	applyColor(current_color)

func kill(natural_death: bool = false) -> void:
	if !natural_death:
		_explode()
	super.kill(natural_death)

func _explode() -> void:
	var player = GameManager.player
	if player and global_position.distance_to(player.global_position) <= explosion_radius:
		var args: LevelBuilderArgs = GameManager.get_level_args()
		var dmg = randf_range(explosion_damage_range.x, explosion_damage_range.y)
		var multiplier = args.enemy_damage_multiplier if args else 1.0
		player.damage(dmg * multiplier, global_position)
	
	if death_vfx:
		var angle = 0.0
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.ENEMY_DEATH, Transform2D(angle, global_position), death_vfx)
