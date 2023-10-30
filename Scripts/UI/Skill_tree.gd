extends Control
class_name SkillsTree

@onready var skill_info_window: SkillInfoWindow = %SkillInfoWindow
@onready var bg = $BG
var skill_nodes_list: Array = []

func _ready() -> void:
	for skill_node in bg.get_children():
		add_child_to_list(skill_node)

func show_skill_info_window(skill_node: SkillNode):
	skill_info_window.set_info_window(skill_node)

func hide_skill_info_window():
	skill_info_window.hide_info_window()

func add_child_to_list(child: SkillNode):
	skill_nodes_list.append(child)


func _on_main_menu_button_pressed() -> void:
	SceneManager.switch_scene("res://Scenes/UI/Main_game_ui.tscn")
