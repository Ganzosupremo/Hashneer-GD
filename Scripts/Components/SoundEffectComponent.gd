class_name SoundEffectComponent extends AudioStreamPlayer2D

var _sound_details: SoundEffectDetails

func play_sound() -> void:
	if not playing:
		play()

func stop_sound() -> void:
	stop()

func set_sound(sound_data: SoundEffectDetails) -> void:
	if sound_data == null: return
	
	_sound_details = sound_data
	stream = _sound_details.audio_stream
	pitch_scale = _sound_details.sound_pitch
	volume_db = _sound_details.sound_volume

func set_and_play_sound(sound_details: SoundEffectDetails) -> void:
	if sound_details == null: return
	
	set_sound(sound_details)
	play_sound()
	await finished

func get_current_sound() -> SoundEffectDetails:
	return _sound_details
