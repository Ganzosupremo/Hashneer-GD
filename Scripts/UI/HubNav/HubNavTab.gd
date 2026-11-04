class_name HubNavTab extends Button
## One tab of the [HubNavBar]. Set [member target] to the screen it opens.
## The tab of the screen that is open is drawn with the "pressed" style and ignores clicks.

signal tab_selected(tab: HubNavTab)

@export var target: SceneManagement.MainScenes = SceneManagement.MainScenes.SKILL_TREE

var is_active: bool = false


func _ready() -> void:
	toggle_mode = true
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)


func set_active(active: bool) -> void:
	is_active = active
	set_pressed_no_signal(active)
	mouse_default_cursor_shape = Control.CURSOR_ARROW if active else Control.CURSOR_POINTING_HAND


func _on_pressed() -> void:
	if is_active:
		# Toggle mode would un-press the open tab, keep it lit instead
		set_pressed_no_signal(true)
		return
	# The bar lights it up if the switch goes through
	set_pressed_no_signal(false)
	tab_selected.emit(self)


func _on_mouse_entered() -> void:
	if not is_active and not disabled:
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_HOVER, AudioManager.DestinationAudioBus.SFX)
