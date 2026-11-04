class_name OrbitalStrikeAbility extends PulseAbility
## Active ability: marks the spot under the mouse and, after [member delay] seconds, a strike lands
## there: the same blast as [PulseAbility], but far away and bigger.

## Seconds between marking the spot and the hit.
@export_range(0.1, 3.0, 0.05) var delay: float = 0.8
## Farthest the strike can land from the player, the mark is pulled in if the mouse is farther.
@export_range(100.0, 3000.0, 10.0) var max_range: float = 900.0
@export var marker_color: Color = Color(1.0, 0.35, 0.25, 0.9)

func _on_activate() -> void:
	var player: PlayerController = get_player()
	if player == null:
		return
	var target: Vector2 = player.get_global_mouse_position()
	var offset: Vector2 = target - player.global_position
	if offset.length() > max_range:
		target = player.global_position + offset.normalized() * max_range
	var marker: Line2D = _show_marker(target)
	await get_tree().create_timer(delay, false).timeout
	if is_instance_valid(marker):
		marker.queue_free()
	# The run may have ended or the player died while waiting
	player = get_player()
	if !is_inside_tree() or !active or player == null or !player.can_move:
		return
	blast(target, damage * player.get_attack_damage_multiplier(), player)

# A shrinking ring on the target so the player and enemies see where it lands
func _show_marker(center: Vector2) -> Line2D:
	var ring: Line2D = Line2D.new()
	ring.width = 4.0
	ring.default_color = marker_color
	ring.top_level = true
	ring.global_position = center
	ring.points = _circle_points(radius)
	add_child(ring)
	var tween: Tween = ring.create_tween()
	tween.tween_method(func(r: float): ring.points = _circle_points(r), radius, radius * 0.15, delay)
	return ring
