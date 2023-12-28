extends Control
class_name SkillsTree

@onready var skill_info_window: SkillInfoWindow = %SkillInfoWindow
var skill_nodes_list: Array = []

func _ready() -> void:
	for skill_node in Interface.find_all_children(%UpgradesHolder):
		if skill_node is SkillNode:
			skill_nodes_list.append(skill_node)
 
func show_skill_info_window(data: SkillUpgradeData):
#	PersistenceDataManager.load_game()
	skill_info_window.set_info_window(data)

func hide_skill_info_window():
	skill_info_window.hide_info_window()

func _on_main_menu_button_pressed() -> void:
	SceneManager.switch_scene("res://Scenes/UI/Main_game_ui.tscn")
