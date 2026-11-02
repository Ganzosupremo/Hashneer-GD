class_name FuryAbility extends BaseAbility
## Active ability: the player deals more damage with every weapon for a few seconds.

## Damage multiplier while it lasts (1.5 = +50%).
@export_range(1.0, 5.0, 0.05) var damage_multiplier: float = 1.5
@export_range(0.5, 30.0, 0.5) var duration: float = 5.0
## Tint of the player while it lasts.
@export var tint: Color = Color(1.0, 0.55, 0.45)

func _on_activate() -> void:
	var player: PlayerController = get_player()
	if player == null:
		return
	player.apply_damage_boost(damage_multiplier, duration, tint)
