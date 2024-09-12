extends Control
class_name SkillsTree

@onready var skill_info_window: SkillInfoWindow = %SkillInfoWindow

var upgrade_data_list: Array = []
static var instance: SkillsTree

func _ready() -> void:
	instance = self
	var i: int = 0
	for skill_node in Interface.find_all_children(%UpgradesHolder):
		if skill_node is SkillNode:
			skill_node.id = i
			skill_node.upgrade_data._id = i
			upgrade_data_list.append(skill_node.upgrade_data)
			i += 1

func show_skill_info_window(data: SkillUpgradeData):
	skill_info_window.set_info_window(data)

func hide_skill_info_window():
	skill_info_window.hide_info_window()


func update_skill_stats(data: SkillUpgradeData):
	if data in upgrade_data_list:
		upgrade_data_list[data._id] = data

func is_skill_unlocked(id: int) -> bool:
	return upgrade_data_list[id].is_unlocked

func unlock_skill(id: int):
	upgrade_data_list[id].is_unlocked = true

static func get_instance() -> SkillsTree:
	return instance

func _on_main_menu_button_pressed() -> void:
	PersistenceDataManager.save_game(true)
	SceneManager.switch_scene("res://Scenes/UI/Main_game_ui.tscn")
