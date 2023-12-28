extends Camera2D
class_name PlayerCamera

var random_strength = 30.0
var shake_decay = 5.0
var rng = RandomNumberGenerator.new()
var shake_strength = 0.0

func _physics_process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_decay * delta)
		offset = random_offset()

func shake(amount: float, decay: float = 5.0) -> void:
	random_strength = amount
	shake_decay = decay
	shake_strength = random_strength

func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
