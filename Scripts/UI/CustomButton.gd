class_name CustomButton extends Button

var _motion_tween: Tween


func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(_refresh_pivot)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)


func _refresh_pivot() -> void:
	pivot_offset = size * 0.5


func _animate_to(target_scale: Vector2, duration: float) -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", target_scale, duration)


func _on_mouse_entered() -> void:
	if not disabled:
		_animate_to(Vector2(1.025, 1.025), 0.11)


func _on_mouse_exited() -> void:
	_animate_to(Vector2.ONE, 0.14)


func _on_focus_entered() -> void:
	if not disabled:
		_animate_to(Vector2(1.025, 1.025), 0.11)


func _on_focus_exited() -> void:
	_animate_to(Vector2.ONE, 0.14)


func _on_button_up() -> void:
	_animate_to(Vector2(1.025, 1.025) if is_hovered() or has_focus() else Vector2.ONE, 0.09)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_RELEASE, AudioManager.DestinationAudioBus.SFX)

func _on_button_down() -> void:
	_animate_to(Vector2(0.975, 0.975), 0.06)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
