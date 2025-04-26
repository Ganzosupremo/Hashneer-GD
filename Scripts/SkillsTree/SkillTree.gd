class_name SkillTreeManager extends Control

@export var skill_nodes: Array = []
@export var player_details: PlayerDetails = PlayerDetails.new()
@export var music_details: MusicDetails

@onready var MAIN_GAME_UI: PackedScene = load("res://Scenes/UI/MainGameUI.tscn")
@onready var quit_game: TweenableButton = $FrontLayer/ButtonContainer/QuitGame
@onready var start_game: TweenableButton = $FrontLayer/ButtonContainer/StartGame
@onready var level_selector_new: LevelSelectorMenu = $LevelSelectorNew

var _use_btc_as_currency: bool = false

func _ready() -> void:
	AudioManager.change_music_clip(music_details)
	skill_nodes = _get_skill_nodes()
	
	var id: int = 0
	for node in skill_nodes:
		node.pressed.connect(Callable(node, "_on_skill_pressed"))
		#node.button_down.connect(Callable(node, "_on_skill_button_down"))
		#node.button_up.connect(Callable(node, "_on_skill_button_up"))
		node.set_node_identifier(id)
		id += 1
	PersistenceDataManager.load_game()

func _get_skill_nodes() -> Array:
	var nodes: Array = []
	for child in %UpgradesHolder.get_children():
		if child is SkillNode:
			nodes.append(child)
	return nodes

func _on_start_game_pressed() -> void:
	PersistenceDataManager.save_game(true)
	await start_game.sound_effect_component_ui.play_sound()
	level_selector_new.open()

func _on_quit_game_pressed() -> void:
	await quit_game.sound_effect_component_ui.play_sound()
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func set_use_btc_bool(value: bool) -> void:
	_use_btc_as_currency = value

	for node in skill_nodes:
		node.set_use_btc_as_currency(_use_btc_as_currency)

func get_use_btc_bool() -> bool:
	return _use_btc_as_currency
