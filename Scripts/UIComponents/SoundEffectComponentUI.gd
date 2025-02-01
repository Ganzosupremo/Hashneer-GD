class_name SoundEffectComponentUI extends AudioStreamPlayer

var _sound_details: SoundEffectDetails
var parent: Button = null

#func _ready() -> void:
	#parent = get_parent()
	#print(parent.name)
	#parent.button_down.connect(_on_mouse_down)
	#parent.button_up.connect(_on_mouse_up)

func _on_mouse_entered() -> void:
	set_sound(parent.on_mouse_entered_effect)
	play_sound()

func _on_mouse_down() -> void:
	set_sound(parent.on_mouse_down_effect)
	play_sound()

func _on_mouse_up() -> void:
	set_sound(parent.on_mouse_up_effect)
	play_sound()

func play_sound() -> void:
	if stream:
		play()
		await finished

func stop_sound() -> void:
	stop()

func set_sound(sound_data: SoundEffectDetails) -> void:
	if !sound_data: return
	
	_sound_details = sound_data
	stream = _sound_details.audio_stream
	pitch_scale = _sound_details.sound_pitch
	volume_db = _sound_details.sound_volume

func set_and_play_sound(sound_details: SoundEffectDetails) -> void:
	set_sound(sound_details)
	await play_sound()

func get_current_sound() -> SoundEffectDetails:
	return _sound_details
