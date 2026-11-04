class_name CongestionFieldAbility extends BaseAbility
## Passive ability: enemies near the player get slowed, like transactions stuck in a full mempool.
##
## Every [member BaseAbility.ability_cooldown] seconds it slows the enemies inside [member radius]
## for a bit longer than that, so they stay slow while they are close.

@export_range(50.0, 800.0, 10.0) var radius: float = 230.0
## Enemy speed multiplier inside the field (0.5 = half speed).
@export_range(0.05, 1.0, 0.05) var slow_multiplier: float = 0.55
@export var field_color: Color = Color(0.45, 0.8, 1.0, 0.12)

func _ready() -> void:
	super._ready()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, field_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(field_color, field_color.a * 3.0), 2.0)

func _on_activate() -> void:
	var player: PlayerController = get_player()
	if player == null:
		return
	var radius_sq: float = radius * radius
	var duration: float = max(get_effective_cooldown(), 0.1) + 0.2
	# "Enemies" is the holder node of the waves mode (EnemiesHolder), mining has no enemies
	var holder: Node = get_tree().get_first_node_in_group("Enemies")
	if holder == null:
		return
	for enemy in holder.get_children():
		if enemy is BaseEnemy and is_instance_valid(enemy) and enemy.global_position.distance_squared_to(player.global_position) <= radius_sq:
			enemy.apply_slow(slow_multiplier, duration)
