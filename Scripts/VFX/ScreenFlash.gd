extends CanvasLayer
class_name ScreenFlash

@onready var rect: ColorRect = $ColorRect

func start_flash(duration: float, color: Color):
	rect.color = color
	rect.modulate.a = 0.0
	show()
	var t: Tween = create_tween()
	t.tween_property(rect, "modulate:a", 1.0, duration * 0.2)
	t.tween_interval(duration * 0.6)
	t.tween_property(rect, "modulate:a", 0.0, duration * 0.2)
	t.tween_callback(Callable(queue_free))
