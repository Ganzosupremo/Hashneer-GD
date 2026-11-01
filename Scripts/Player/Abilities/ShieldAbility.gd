class_name ShieldAbility extends BaseAbility
## Player ability that wraps a [ShieldComponent]. The component on its own is not a [BaseAbility], so
## the player could not equip it (unlocking Shield crashed the game on play).[br]
## The shield absorbs hits through the player's [HealthComponent]. Once it breaks it comes back,
## whole, after [member BaseAbility.ability_cooldown] seconds.

@onready var _shield: ShieldComponent = $ShieldComponent

var _health: HealthComponent

func _ready() -> void:
	super._ready()
	var player: Node = get_parent()
	if player is Node2D:
		# Bullets that hit the shield spare its owner; the owner is the player, not this node
		_shield.set_parent_entity(player)
	if player and player.has_method("get_health_node"):
		_health = player.get_health_node()
	_shield.shield_depleted.connect(_on_shield_depleted)
	_set_shield_on(false)

func enable() -> void:
	super.enable()
	_shield.reset_shield()
	_set_shield_on(true)

func disable() -> void:
	super.disable()
	_set_shield_on(false)

## Only rebuilds the shield once it broke and the cooldown ran out.
func is_ability_ready() -> bool:
	return super.is_ability_ready() and _shield.destroyed

func _on_activate() -> void:
	_shield.reset_shield()

func _on_shield_depleted() -> void:
	_reset_cooldown_timer()

func _set_shield_on(on: bool) -> void:
	_shield.set_deferred("monitoring", on)
	_shield.visible = on
	if _health:
		_health.has_shield = on
		_health.shield = _shield if on else null
