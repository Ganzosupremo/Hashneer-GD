extends Panel
class_name NotificationPanel

@onready var label: Label = %Label

func _ready():
	# Start hidden and fade in/out
	modulate.a = 0.0

func tween_panel(text: String, duration: float = 2.0, fade_time: float = 0.3) -> void:
	_set_text(text)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

	await tween.finished

func _set_text(text: String) -> void:
	_set_label()
	label.text = text

func _set_label() -> void:
	if label: return
	label = %Label
