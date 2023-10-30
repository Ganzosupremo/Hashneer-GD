extends Area2D
class_name CenterBlock

signal block_center_mined()
@export var intial_health: float = 50.0

var current_health: float = 0.0
static var instance: CenterBlock: get = get_instance

func _ready() -> void:
	instance = self
	current_health = intial_health

func take_damage(damage: float) -> void:
	current_health -= damage
	print(current_health)
	if	current_health <= 0.0:
		emit_signal("block_center_mined")
		queue_free()

static  func get_instance() -> CenterBlock:
	return instance
