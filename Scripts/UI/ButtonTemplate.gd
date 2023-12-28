extends Button

var original_size: Vector2 = scale
var grow_size: Vector2 = Vector2(1.1, 1.1)

func _on_mouse_entered() -> void:
	grow_button(grow_size, 0.2)

func _on_mouse_exited() -> void:
	grow_button(original_size, 0.2)

func grow_button(end_size: Vector2, duration: float) -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "scale", end_size, duration)
