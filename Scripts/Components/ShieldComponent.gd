class_name ShieldComponent extends Node

signal shield_depleted()
signal shield_changed(new_value: float)

@export var max_shield: float = 100.0
@export var shield_regen_rate: float = 5.0
@export var shield_regen_delay: float = 3.0
@export var can_regen: bool = false

var current_shield: float:
	set(value):
		current_shield = clamp(value, 0, max_shield)
		shield_changed.emit(current_shield)
		if current_shield <= 0.0:
			shield_depleted.emit()

var _regen_timer: float = 0.0

func _ready() -> void:
	current_shield = max_shield

func _process(delta: float) -> void:
	if not can_regen:
		return

	if _regen_timer > 0:
		_regen_timer -= delta
	elif current_shield < max_shield:
		current_shield += shield_regen_rate * delta

func absord_damage(amount: float) -> float:
	_regen_timer = shield_regen_delay
	
	var remaining_damage: float = max(0, amount - current_shield)
	current_shield = max(0, current_shield - amount)
	
	return remaining_damage

func is_active() -> bool:
	return current_shield > 0
