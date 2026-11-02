class_name PulseAbility extends BaseAbility
## Active ability: a blast around the player that hurts every enemy and breaks the blocks in range.

@export_range(50.0, 1000.0, 10.0) var radius: float = 260.0
## Damage before the player's damage multiplier.
@export_range(1.0, 5000.0, 1.0) var damage: float = 120.0
## Push given to enemies.
@export_range(0.0, 100000.0, 100.0) var force: float = 25000.0
@export_flags_2d_physics var collision_mask: int = 0xFFFFFFFF

func _on_activate() -> void:
	var player: PlayerController = get_player()
	if player == null:
		return
	var center: Vector2 = player.global_position
	var final_damage: float = damage * player.get_attack_damage_multiplier()
	var quadrant_builder: QuadrantBuilder = get_tree().get_first_node_in_group("QuadrantBuilder")

	if GameManager.vfx_manager:
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.EXPLOSION, Transform2D(0.0, center))
	AudioManager.create_2d_audio_at_location(center, SoundEffectDetails.SoundEffectType.QUADRANT_CORE_DESTROYED, AudioManager.DestinationAudioBus.SFX)
	if GameManager._player_camera:
		GameManager._player_camera.add_trauma(0.5)
	_show_ring(center)

	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, center)
	params.collision_mask = collision_mask
	params.collide_with_bodies = true
	params.exclude = [player.get_rid()]
	var results: Array = get_world_2d().direct_space_state.intersect_shape(params, 64)
	# A body with several shapes comes back once per shape, hit it once
	var bodies: Array = []
	for result in results:
		if is_instance_valid(result.collider) and !bodies.has(result.collider):
			bodies.append(result.collider)
	for body in bodies:
		if is_instance_valid(body):
			_hit(body, center, final_damage, quadrant_builder)

func _hit(body: Object, center: Vector2, final_damage: float, quadrant_builder: QuadrantBuilder) -> void:
	if not body is Node2D:
		return
	var direction: Vector2 = center.direction_to(body.global_position)
	# Cut where the blast meets the body, not at the player
	var hit_pos: Vector2 = center + direction * min(center.distance_to(body.global_position), radius * 0.8)
	if body is BlockCore and quadrant_builder:
		quadrant_builder.fracture_block_core(final_damage, "Player")
	elif body is FracturableStaticBody2D and quadrant_builder:
		quadrant_builder.fracture_quadrant_on_collision(hit_pos, body, 1000.0, final_damage, 1000.0)
	elif body is BaseEnemy and body.has_active_shield():
		body.shield.absorb_damage(final_damage, hit_pos)
	elif body is BaseEnemy:
		body.call_deferred("damage", Vector2(final_damage, final_damage) * 0.5, hit_pos, direction * force, 0.25, Color.MISTY_ROSE)

# A quick expanding ring so the player sees the reach
func _show_ring(center: Vector2) -> void:
	var ring: Line2D = Line2D.new()
	ring.width = 6.0
	ring.default_color = Color(1.0, 0.8, 0.3, 0.9)
	ring.top_level = true
	ring.global_position = center
	ring.points = _circle_points(10.0)
	add_child(ring)
	var tween: Tween = ring.create_tween().set_parallel(true)
	tween.tween_method(func(r: float): ring.points = _circle_points(r), 10.0, radius, 0.25)
	tween.tween_property(ring, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(ring.queue_free)

func _circle_points(r: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i in 33:
		points.append(Vector2.RIGHT.rotated(TAU * i / 32.0) * r)
	return points
