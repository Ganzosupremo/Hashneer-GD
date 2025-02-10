class_name LevelSelectorMenu extends Control

@export var scene_to_load: PackedScene

@onready var level_name: AnimatedLabel = %LevelName
@onready var level_size: AnimatedLabel = %LevelSize
@onready var quadrants_health: AnimatedLabel = %QuadrantsHealth
@onready var block_core_health: AnimatedLabel = %BlockCoreHealth

@onready var previous_level_button: TweenableButton = %PreviousLevelButton
@onready var next_level_button: TweenableButton = %NextLevelButton

var _current_level_index: int = 0

func _ready() -> void:
	self.hide()
	_setup_buttons()


func open() -> void:
	_current_level_index = GameManager.levels_unlocked - 1
	_current_level_index = clampi(_current_level_index, 0, GameManager.game_levels.size() - 1)
	_update_level_info()
	_update_button_states()
	_update_builder_args(_current_level_index)
	self.show()

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

func _on_enter_game_pressed() -> void:
	SceneManager.switch_scene_with_packed(scene_to_load)

func _update_builder_args(index: int) -> void:
	GameManager._set_level_index(index)
	GameManager.select_builder_args(index)

func _update_level_info() -> void:
	if GameManager.game_levels.size() == 0: return
	
	var level: QuadrantBuilderArgs = GameManager.game_levels[_current_level_index]
	
	level_name.set_text("Level %d" % (level.level_index + 1))
	level_size.set_text("Map Size: %dx%d" % [level.grid_size.x, level.grid_size.y])
	quadrants_health.set_text("Block's Health: %d" % level.initial_health)
	block_core_health.set_text("Block Core's Health: %d" % level.initial_health)

	_update_button_states()

func _on_exit_button_pressed() -> void:
	self.hide()
