class_name RippleComponentUI extends ColorRect

var ripple_pos: Vector2 = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and event.pressed:
			var pos: Vector2 = GameManager.to_local(event.position)/self.size
			_create_ripple(pos)

func _create_ripple(pos: Vector2) -> void:
	ripple_pos = pos
	material["shader_parameter/circle_center"] = pos
	animate_ripple()

func set_ripple_position(pos: Vector2) -> void:
	ripple_pos = pos
	material["shader_parameter/circle_center"] = pos

func animate_ripple() -> void:
	var tween: Tween = GameManager.init_tween().set_parallel(true)
	tween.tween_property(material, "shader_parameter/time", 1.0, 1.0).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
