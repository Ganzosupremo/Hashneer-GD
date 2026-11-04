class_name DashAbility extends BaseAbility
## Active ability: a quick dash where the player is moving (or toward the mouse when standing still),
## ignoring damage while it lasts. Damages and pushes the enemies it passes through.

@export_range(300.0, 3000.0, 50.0) var dash_speed: float = 1500.0
@export_range(0.05, 1.0, 0.01) var dash_time: float = 0.18
## Extra seconds without damage after the dash ends.
@export_range(0.0, 2.0, 0.05) var extra_invulnerability: float = 0.15
## Damage to each enemy the dash goes through, before the player's damage multiplier. 0 = none.
@export_range(0.0, 2000.0, 1.0) var contact_damage: float = 40.0
## Radius around the player that counts as "passing through" an enemy.
@export_range(10.0, 200.0, 5.0) var hit_radius: float = 45.0
@export var trail_color: Color = Color(0.55, 0.85, 1.0, 0.8)

var _hit_enemies: Array = []

func _process(delta: float) -> void:
	super._process(delta)
	var player: PlayerController = get_player()
	if player and player.is_dashing():
		_hit_along_dash(player)

func _on_activate() -> void:
	var player: PlayerController = get_player()
	if player == null:
		return
	var direction: Vector2 = player.get_input()
	if direction == Vector2.ZERO:
		direction = player.global_position.direction_to(player.get_global_mouse_position())
	if direction == Vector2.ZERO:
		return
	_hit_enemies.clear()
	player.start_dash(direction, dash_speed, dash_time)
	player.grant_invulnerability(dash_time + extra_invulnerability)
	_spawn_trail(player, direction)

func _hit_along_dash(player: PlayerController) -> void:
	if contact_damage <= 0.0:
		return
	var holder: Node = get_tree().get_first_node_in_group("Enemies")
	if holder == null:
		return
	var final_damage: float = contact_damage * player.get_attack_damage_multiplier()
	for enemy in holder.get_children():
		if not enemy is BaseEnemy or !is_instance_valid(enemy) or _hit_enemies.has(enemy):
			continue
		if enemy.global_position.distance_to(player.global_position) > hit_radius + 30.0:
			continue
		_hit_enemies.append(enemy)
		var direction: Vector2 = player.velocity.normalized()
		var hit_pos: Vector2 = enemy.global_position.move_toward(player.global_position, 20.0)
		if enemy.has_active_shield():
			enemy.shield.absorb_damage(final_damage, hit_pos)
		else:
			enemy.call_deferred("damage", Vector2(final_damage, final_damage) * 0.5, hit_pos, direction * 15000.0, 0.2, Color.LIGHT_BLUE)

# A short streak behind the player
func _spawn_trail(player: PlayerController, direction: Vector2) -> void:
	var trail: Line2D = Line2D.new()
	trail.top_level = true
	trail.width = 18.0
	trail.default_color = trail_color
	var start: Vector2 = player.global_position
	trail.points = PackedVector2Array([start, start + direction * dash_speed * dash_time])
	add_child(trail)
	var tween: Tween = trail.create_tween().set_parallel(true)
	tween.tween_property(trail, "width", 0.0, 0.3)
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(trail.queue_free)
