class_name TankEnemy extends BaseEnemy

@export var armor_reduction: float = 0.5

func _ready() -> void:
	super._ready()

func damage(damage_to_apply: Vector2, point: Vector2, knockback_force: Vector2, knockback_time: float, damage_color: Color) -> Dictionary:
	var reduced_damage = damage_to_apply * armor_reduction
	return super.damage(reduced_damage, point, knockback_force * armor_reduction, knockback_time, damage_color)
