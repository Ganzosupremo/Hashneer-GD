class_name LevelSelectorMenu extends Control

@onready var level_name: Label = %LevelName

@onready var previous_level_button: CustomButton = %PreviousLevelButton
@onready var next_level_button: CustomButton = %NextLevelButton

var _current_level_index: int = 0

func _ready() -> void:
	self.hide()
	_setup_buttons()

func open() -> void:
	_current_level_index = GameManager.levels_unlocked - 1
	_current_level_index = clampi(_current_level_index, 0, GameManager.game_levels.size() - 1)
	_update_level_info()
	_update_builder_args(_current_level_index)
	self.show()
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_OPEN_SOUND, AudioManager.DestinationAudioBus.SFX)

func _setup_buttons() -> void:
	_update_button_states()

func _update_button_states() -> void:
	previous_level_button.disabled = _current_level_index <= 0
	next_level_button.disabled = (
		_current_level_index >= GameManager.game_levels.size() - 1 
		or _current_level_index >= GameManager.levels_unlocked - 1
	)

func _on_next_level_pressed() -> void:
	if _current_level_index < GameManager.game_levels.size() - 1:
		_current_level_index += 1
		_update_button_states()
		_update_level_info()
		_update_builder_args(_current_level_index)

func _on_previous_level_pressed() -> void:
	if _current_level_index > 0:
		_current_level_index -= 1
		_update_button_states()
		_update_level_info()
		_update_builder_args(_current_level_index)

func _update_builder_args(index: int) -> void:
	GameManager._set_level_index(index)
	GameManager.select_builder_args(index)

func _update_level_info() -> void:
	if GameManager.game_levels.size() == 0: return
	
	var level: LevelBuilderArgs = GameManager.game_levels[_current_level_index]
	
	level_name.set_text("%d" % (level.level_index))
	_update_button_states()

func _on_enter_game_pressed() -> void:
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.MINING_GAME_MODE)

func _on_exit_button_pressed() -> void:
	self.hide()
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_CLOSE_SOUND, AudioManager.DestinationAudioBus.SFX)

func _on_waves_game_mode_pressed() -> void:
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.UNLIMITED_WAVES_GAME_MODE)
