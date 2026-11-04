class_name BaseAbility extends Node2D
## Base class for the player's abilities.
##
## [b]Passive[/b] abilities (support: Magnet, Regen, Shield, Block Core Finder) run on their own
## every [member ability_cooldown] seconds; the player can equip up to 3.[br]
## [b]Active[/b] abilities (they add damage) only run when the player presses the
## [code]Active_Ability[/code] action (Q) and then recharge; the player can equip 1.
## See [code]Equipment[/code] for the loadout.

enum AbilityKind {
	PASSIVE, ## Support, runs on its own with its cooldown.
	ACTIVE, ## Adds damage, used with Q.
}

@export var ability_name: String = "Ability Name"
@export_multiline var ability_description: String = "Ability Description"
@export var ability_cooldown: float = 0.0
@export var ability_kind: AbilityKind = AbilityKind.PASSIVE
## Optional icon for the HUD and the Armory.
@export var ability_icon: Texture2D

var active: bool = false
var current_cooldown: float = 0.0

func _ready() -> void:
	current_cooldown = ability_cooldown

func _process(delta: float) -> void:
	if !active: return
	current_cooldown -= delta
	if ability_kind == AbilityKind.PASSIVE:
		activate()

## This method is the entry point for the ability activation.
func activate() -> void:
	if is_ability_ready():
		_on_activate()
		_reset_cooldown_timer()

## Uses an active ability if it's ready. Returns true if it was used.
func try_activate() -> bool:
	if !is_ability_ready():
		return false
	_on_activate()
	_reset_cooldown_timer()
	return true

func is_ability_ready() -> bool:
	return get_active_state() and current_cooldown <= 0.0

## Seconds until the ability can be used again (0 = ready).
func get_cooldown_left() -> float:
	return max(current_cooldown, 0.0)

func is_active_kind() -> bool:
	return ability_kind == AbilityKind.ACTIVE

func enable() -> void:
	show()
	active = true
	# Active abilities start ready, passive ones wait for their first cooldown as before
	if is_active_kind():
		current_cooldown = 0.0

func disable() -> void:
	active = false
	hide()

## This method will be overwritten by the child class.
## It will contain the logic for the ability.
func _on_activate() -> void:
	pass

func _reset_cooldown_timer() -> void:
	current_cooldown = get_effective_cooldown()

## [member ability_cooldown] after the player's "Ability Cooldown" skills.
func get_effective_cooldown() -> float:
	var player: PlayerController = get_player()
	if player:
		return ability_cooldown * player.ability_cooldown_multiplier
	return ability_cooldown

func get_active_state() -> bool:
	return active

## The player that owns this ability (its parent), or null.
func get_player() -> PlayerController:
	return get_parent() as PlayerController
