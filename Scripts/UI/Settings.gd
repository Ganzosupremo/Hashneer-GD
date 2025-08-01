class_name SettingsUI extends Control

signal visibility_state_changed(visible: bool)

@onready var resolutions: OptionButton = %Resolutions
@onready var vsync: CheckButton = %Vsync
@onready var fullscreen: CheckButton = %Fullscreen

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var player_sfx_slider: HSlider = %PlayerSFXSlider
@onready var weapons_sfx_slider: HSlider = %WeaponsSFXSlider

@onready var _video_settings: VBoxContainer = %VideoSettings
@onready var _audio_settings: VBoxContainer = %AudioSettings


var _loaded: bool = false

func _ready() -> void:
	# Populate resolutions
	var available_resolutions = [
		Vector2(1024, 768),
		Vector2(1152, 648),
		Vector2(1280, 720),
		Vector2(1920, 1080),
		Vector2(2560, 1440),
		Vector2(3840, 2160)
	]
	
	for res in available_resolutions:
		resolutions.add_item("%dx%d" % [res.x, res.y])

	resolutions.select(UserSettings.get_resolution_index())
	vsync.button_pressed = UserSettings.is_vsync_enabled()
	fullscreen.button_pressed = UserSettings.is_fullscreen()

	master_slider.value = UserSettings.get_master_volume()
	music_slider.value = UserSettings.get_music_volume()
	sfx_slider.value = UserSettings.get_sfx_volume()
	player_sfx_slider.value = UserSettings.get_player_sfx_volume()
	weapons_sfx_slider.value = UserSettings.get_weapons_volume()
	_loaded = true


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_visibility()

func toggle_visibility() -> void:
	if visible:
		hide()
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_CLOSE_SOUND, AudioManager.DestinationAudioBus.SFX)
		visibility_state_changed.emit(visible)
	else:
		show()
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_OPEN_SOUND, AudioManager.DestinationAudioBus.SFX)
		visibility_state_changed.emit(visible)

func _enable_vsync(mode: DisplayServer.VSyncMode) -> void:
	match mode:
		DisplayServer.VSYNC_ENABLED:
			vsync.button_pressed = true
		DisplayServer.VSYNC_DISABLED:
			vsync.button_pressed = false

func _on_resolution_selected(index: int) -> void:
	var resolution_text = resolutions.get_item_text(index)
	var resolution = resolution_text.split("x")
	var res: Vector2i = Vector2i(resolution[0].to_int(), resolution[1].to_int())
	UserSettings.set_resolution(res, index)

func _on_window_modes_item_selected(index: int) -> void:
	match index:
		0:
			UserSettings.set_window_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
			UserSettings.set_window_flags(DisplayServer.WindowFlags.WINDOW_FLAG_BORDERLESS, false)
		1:
			UserSettings.set_window_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
		2:
			UserSettings.set_window_mode(DisplayServer.WindowMode.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		3:
			UserSettings.set_window_flags(DisplayServer.WindowFlags.WINDOW_FLAG_BORDERLESS)

func _on_vsync_toggled(button_pressed: bool) -> void:
	UserSettings.set_vsync(button_pressed)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	UserSettings.set_fullscreen(button_pressed)

func _on_sfx_slider_value_changed(value: float) -> void:
	UserSettings.set_sfx_volume(value)
	if !_loaded: return
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_VOLUME_SLIDER_TEST, AudioManager.DestinationAudioBus.SFX)

func _on_music_slider_value_changed(value: float) -> void:
	UserSettings.set_music_volume(value)

func _on_master_slider_value_changed(value: float) -> void:
	UserSettings.set_master_volume(value)

func _on_player_sfx_slider_value_changed(value: float) -> void:
	UserSettings.set_player_sfx_volume(value)
	if !_loaded: return
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.PLAYER_HIT, AudioManager.DestinationAudioBus.PLAYER_SFX)

func _on_weapons_slider_value_changed(value: float) -> void:
	UserSettings.set_weapons_volume(value)
	if !_loaded: return
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.AK47_RIFLE_FIRE, AudioManager.DestinationAudioBus.WEAPONS)

func _on_video_button_pressed() -> void:
	_video_settings.show()
	_audio_settings.hide()

func _on_audio_button_pressed() -> void:
	_audio_settings.show()
	_video_settings.hide()


func _on_close_button_pressed() -> void:
	toggle_visibility()
