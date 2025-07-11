class_name BaseAbility extends Node2D

@export var ability_name: String = "Ability Name"
@export var ability_description: String = "Ability Description"
@export var ability_cooldown: float = 0.0

var active: bool = false
var current_cooldown: float = 0.0

func _ready() -> void:
	current_cooldown = ability_cooldown

func _process(delta: float) -> void:
	if !active: return
	current_cooldown -= delta
	activate()

## This method is the entry point for the ability activation.
func activate() -> void:
	if is_ability_ready():
		_on_activate()
		_reset_cooldown_timer()

func is_ability_ready() -> bool:
	return get_active_state() and current_cooldown <= 0.0

func enable() -> void:
	show()
	active = true

func disable() -> void:
	active = false
	hide()

## This method will be overwritten by the child class.
## It will contain the logic for the ability.
func _on_activate() -> void:
	pass

func _reset_cooldown_timer() -> void:
	current_cooldown = ability_cooldown

func get_active_state() -> bool:
	return active
