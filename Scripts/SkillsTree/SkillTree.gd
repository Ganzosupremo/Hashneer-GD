class_name SkillTreeManager extends Control

@export var skill_nodes: Array = []
@export var player_details: PlayerDetails = PlayerDetails.new()

@onready var MAIN_GAME_UI: PackedScene = load("res://Scenes/UI/MainGameUI.tscn")
@onready var LEVELS_SELECTOR: PackedScene = preload("res://Scenes/UI/Levels_selector.tscn")

func _ready() -> void:
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
	PersistenceDataManager.save_game(true)
	SceneManager.switch_scene_with_packed(LEVELS_SELECTOR)


func _on_quit_game_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
