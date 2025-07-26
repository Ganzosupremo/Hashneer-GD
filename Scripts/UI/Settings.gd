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


var vsync_mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED
var loaded: bool = false

const SettingsSaveName = "user_settings"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

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
	
	for resolution in available_resolutions:
		resolutions.add_item("%dx%d" % [resolution.x, resolution.y])
	
	# Set current resolution
	var current_resolution = DisplayServer.window_get_size()
	for i in range(resolutions.get_item_count()):
		if resolutions.get_item_text(i) == "%dx%d" % [current_resolution.x, current_resolution.y]:
			resolutions.select(i)
			break
	
	# Set V-Sync state
	var mode: DisplayServer.VSyncMode = DisplayServer.window_get_vsync_mode()
	_enable_vsync(mode)
	# Set Fullscreen state
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
	
	# Connect signals
	resolutions.item_selected.connect(_on_resolution_selected)
	vsync.toggled.connect(_on_vsync_toggled)
	fullscreen.toggled.connect(_on_fullscreen_toggled)

	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume


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
	DisplayServer.window_set_size(Vector2i(int(resolution[0]), int(resolution[1])))

func _on_vsync_toggled(button_pressed: bool) -> void:
	if vsync.button_pressed:
		vsync_mode = DisplayServer.VSYNC_ENABLED
	else:
		vsync_mode = DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED)

func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	if !loaded: return
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_VOLUME_SLIDER_TEST, AudioManager.DestinationAudioBus.SFX)

func _on_music_slider_value_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_master_slider_value_changed(value: float) -> void:
	AudioManager.set_master_volume(value)

func _on_player_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_player_sfx_volume(value)
	if !loaded: return
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.PLAYER_HIT, AudioManager.DestinationAudioBus.PLAYER_SFX)

func _on_weapons_slider_value_changed(value: float) -> void:
	AudioManager.set_weapons_volume(value)
	if !loaded: return
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.AK47_RIFLE_FIRE, AudioManager.DestinationAudioBus.WEAPONS)

func save_data() -> void:
	var settings = {
		"resolution": {
			"window_size": resolutions.get_item_text(resolutions.get_selected_id()),
			"index": resolutions.get_item_index(resolutions.get_selected_id())
		},
		"fullscreen": DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN,
		"vsync": vsync_mode,
		"master_volume": AudioManager.master_volume,
		"music_volume": AudioManager.music_volume,
		"sfx_volume": AudioManager.sfx_volume,
		"player_sfx_volume": AudioManager.player_sfx_volume,
		"weapons_volume": AudioManager.weapons_volume
	}
	SaveSystem.set_var(SettingsSaveName, settings)

func load_data() -> void:
	if !SaveSystem.has(SettingsSaveName): return
	
	var settings = SaveSystem.get_var(SettingsSaveName)
	var res: String = settings["resolution"]["window_size"]
	var window_size: Array = res.split("x")
	DisplayServer.window_set_size(Vector2i(window_size[0].to_int(), window_size[1].to_int()))
	DisplayServer.window_set_mode(settings["fullscreen"] if DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN else DisplayServer.WindowMode.WINDOW_MODE_MAXIMIZED)
	_enable_vsync(settings["vsync"])
	AudioManager.set_master_volume(settings["master_volume"])
	AudioManager.set_music_volume(settings["music_volume"])
	AudioManager.set_sfx_volume(settings["sfx_volume"])
	AudioManager.set_player_sfx_volume(settings["player_sfx_volume"])
	AudioManager.set_weapons_volume(settings["weapons_volume"])

	master_slider.value = AudioManager.master_volume
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	player_sfx_slider.value = AudioManager.player_sfx_volume
	weapons_sfx_slider.value = AudioManager.weapons_volume
	resolutions.select(settings["resolution"]["index"])
	vsync.button_pressed = settings["vsync"] == DisplayServer.VSYNC_ENABLED
	fullscreen.button_pressed = settings["fullscreen"]
	loaded = true


func _on_video_button_pressed() -> void:
	_video_settings.show()
	_audio_settings.hide()

func _on_audio_button_pressed() -> void:
	_audio_settings.show()
	_video_settings.hide()


func _on_close_button_pressed() -> void:
	toggle_visibility()
