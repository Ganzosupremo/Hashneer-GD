class_name SkillTreeManager extends Control

@export var skill_nodes: Array = []
@export var player_details: PlayerDetails = PlayerDetails.new()

@onready var MAIN_GAME_UI: PackedScene = load("res://Scenes/UI/MainGameUI.tscn")

const PLAYER_DETAILS_SAVE_KEY: String = "player_saved_data"
const implements: Array = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

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

func _on_main_menu_button_pressed() -> void:
	PersistenceDataManager.save_game()
	SceneManager.switch_scene_with_packed(MAIN_GAME_UI)

func save_data() -> void:
	pass
	# var player_data: PlayerSaveData = PlayerSaveData.new(player_details.speed, player_details.max_health, player_details.initial_weapon, player_details.weapons_array, player_details)
	# SaveSystem.set_var(PLAYER_DETAILS_SAVE_KEY, player_data)

func load_data() -> void:
	pass
	#if !SaveSystem.has(PLAYER_DETAILS_SAVE_KEY): return
	#
	#var data: Dictionary = SaveSystem.get_var(PLAYER_DETAILS_SAVE_KEY)
	#print("Player data loaded: {0}".format([data]))
#
	#var res = Utils.dict_to_resource(data, PlayerSaveData.new(), true)
	#for i in res.saved_weapons_array.size():
		#res.saved_weapons_array[i] = Utils.dict_to_resource(res.saved_weapons_array[i], WeaponDetails.new(), true)
		#print("Weapon details loaded: {0}".format([res.saved_weapons_array[i]]))
	#
	#self.player_details = res.player_details
	#self.player_details.weapons_array = res.saved_weapons_array
	#self.player_details.speed = res.speed
	#self.player_details.max_health = res.max_health
