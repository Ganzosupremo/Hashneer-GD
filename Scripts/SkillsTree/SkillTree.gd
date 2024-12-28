class_name SkillTreeManager extends Control

@export var skill_nodes: Array = []

var UPGRADE_ACTIONS: Dictionary = {
	SkillNode.UPGRADE_TYPE.HEALTH: func(resource): resource.max_health += 10,
	SkillNode.UPGRADE_TYPE.SPEED: func(resource): resource.speed += 5,
	SkillNode.UPGRADE_TYPE.DAMAGE: func(resource): resource.damage += 3,
}

@onready var MAIN_GAME_UI: PackedScene = load("res://Scenes/UI/MainGameUI.tscn")

#const implements = [
	#preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
#]

func _exit_tree() -> void:
	PersistenceDataManager.save_game()

func _ready() -> void:
	PersistenceDataManager.load_game()
	skill_nodes = _get_skill_nodes()
	
	var id: int = 0
	for node in skill_nodes:
		node.pressed.connect(Callable(node, "_on_skill_pressed"))
		node.node_identifier = id
		
		#if node.node_identifier == 0:
			#node.unlock()
		#else:
			#print_debug("Locking nodes...")
			#node.lock()
		id += 1

func _get_skill_nodes() -> Array:
	var nodes: Array = []
	for child in %UpgradesHolder.get_children():
		if child is SkillNode:
			nodes.append(child)
	return nodes

#func save_data() -> void:
	#for node in skill_nodes:
		#node.set_var_to_save()
#
#func load_data() -> void:
	#for node in skill_nodes:
		#node.get_var_to_load()

func _on_main_menu_button_pressed() -> void:
	PersistenceDataManager.save_game()
	SceneManager.switch_scene_with_packed(MAIN_GAME_UI)
