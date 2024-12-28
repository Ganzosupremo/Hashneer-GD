class_name SoundEffectComponent extends AudioStreamPlayer

var _sound_details: SoundEffectDetails

func play_sound() -> void:
	if stream:
		play()

func stop_sound() -> void:
	stop()

func set_sound(sound_effect: SoundEffectDetails) -> void:
	if !sound_effect: return
	
	_sound_details = sound_effect
	stream = _sound_details.audio_stream
	pitch_scale = _sound_details.sound_pitch
	volume_db = _sound_details.sound_volume

func set_and_play_sound(sound_details: SoundEffectDetails) -> void:
	set_sound(sound_details)
	play_sound()

func get_current_sound() -> SoundEffectDetails:
	return _sound_details
