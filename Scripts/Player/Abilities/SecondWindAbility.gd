class_name SecondWindAbility extends BaseAbility
## Passive ability: when health drops below [member health_threshold], heals the player and makes
## them ignore damage for a moment. Then it recharges for [member BaseAbility.ability_cooldown] seconds.

## Share of max health that triggers it (0.25 = below 25%).
@export_range(0.05, 0.9, 0.05) var health_threshold: float = 0.25
## Share of max health healed.
@export_range(0.05, 1.0, 0.05) var heal_share: float = 0.35
## Seconds the player ignores damage after it triggers.
@export_range(0.0, 5.0, 0.1) var invulnerability_time: float = 1.5

func enable() -> void:
	super.enable()
	# Ready from the start: it's a safety net, not something to wait for
	current_cooldown = 0.0

# Checked every frame while ready, the cooldown only starts when it triggers
func activate() -> void:
	if !is_ability_ready():
		return
	var player: PlayerController = get_player()
	if player == null or player.get_max_health() <= 0.0:
		return
	var health_share: float = player.get_current_health() / player.get_max_health()
	if health_share <= 0.0 or health_share > health_threshold:
		return
	_on_activate()
	_reset_cooldown_timer()

func _on_activate() -> void:
	var player: PlayerController = get_player()
	player.get_health_node().heal(player.get_max_health() * heal_share)
	player.grant_invulnerability(invulnerability_time)
	if GameManager.vfx_manager:
		GameManager.vfx_manager.spawn_effect(VFXManager.EffectType.EXPLOSION, Transform2D(0.0, player.global_position))
	if GameManager._player_camera:
		GameManager._player_camera.add_trauma(0.3)
