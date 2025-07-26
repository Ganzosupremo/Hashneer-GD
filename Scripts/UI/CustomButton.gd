class_name CustomButton extends Button

#region Signals

func _on_button_up() -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_RELEASE, AudioManager.DestinationAudioBus.SFX)

func _on_button_down() -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)

	#endregion
