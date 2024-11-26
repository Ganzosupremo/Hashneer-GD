class_name SkillTreeManager extends Control

@export var skill_nodes: Array = []

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _enter_tree() -> void:
	skill_nodes = _get_skill_nodes()
	PersistenceDataManager.load_game()

func _exit_tree() -> void:
	PersistenceDataManager.save_game()

func _ready() -> void:
	for d in range(skill_nodes.size()):
		skill_nodes[d].id = d
		skill_nodes[d].set_line_points()
		if skill_nodes[0].id == d:
			skill_nodes[0].unlock()
			continue
		
		skill_nodes[d].lock()
	#var i: int = 0
	#for node in skill_nodes:
		#node.id = i
		#if skill_nodes[0] == node:
			#node.unlock()
		#node.lock()
		#i += 1
	#var i: int = 0
	#for skill_node in skill_nodes:
		#if skill_node is SkillNode:
			#skill_node.pressed.connect(skill_node.try_apply_upgrade)
			#skill_node.id = i
			#skill_node.upgrade_data._id = i
			#upgrade_data_list.append(skill_node.upgrade_data)
			#i += 1

#func show_skill_info_window(data: UpgradeData):
	#skill_info_window.set_info_window(data)
#func hide_skill_info_window():
	#skill_info_window.hide_info_window()
#func update_skill_stats(data: UpgradeData):
	#if data in upgrade_data_list:
		#upgrade_data_list[data._id] = data
#func is_skill_unlocked(id: int) -> bool:
	#return upgrade_data_list[id].is_unlocked
#func unlock_skill(id: int):
	#upgrade_data_list[id].is_unlocked = true
#static func get_instance() -> SkillTreeManager:
	#return instance

func _get_skill_nodes() -> Array:
	var nodes: Array = []
	for child in %UpgradesHolder.get_children():
		if child is SkillNode:
			nodes.append(child)
	return nodes


func save_data() -> void:
	for node in skill_nodes:
		node.set_var_to_save()
	

func load_data() -> void:
	for node in skill_nodes:
		node.get_var_to_load()

func _on_main_menu_button_pressed() -> void:
	PersistenceDataManager.save_game()
	SceneManager.switch_scene("res://Scenes/UI/Main_game_ui.tscn")
