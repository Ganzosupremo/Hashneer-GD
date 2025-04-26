class_name SkillTreeManager extends Control

@export var skill_nodes: Array = []
@export var player_details: PlayerDetails = PlayerDetails.new()
@export var music_details: MusicDetails

@onready var MAIN_GAME_UI: PackedScene = load("res://Scenes/UI/MainGameUI.tscn")
@onready var quit_game: TweenableButton = $FrontLayer/ButtonContainer/QuitGame
@onready var start_game: TweenableButton = $FrontLayer/ButtonContainer/StartGame
@onready var level_selector_new: LevelSelectorMenu = $LevelSelectorNew

func _exit_tree() -> void:
	PersistenceDataManager.save_game(true)
	print("Saving game data...")

func _ready() -> void:
	AudioManager.change_music_clip(music_details)
	skill_nodes = _get_skill_nodes()
	
	var id: int = 0
	for node in skill_nodes:
		node.pressed.connect(Callable(node, "_on_skill_pressed"))
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
	# PersistenceDataManager.save_game(true)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, SoundEffectDetails.DestinationAudioBus.SFX)
	level_selector_new.open()

func _on_quit_game_pressed() -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, SoundEffectDetails.DestinationAudioBus.SFX)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
