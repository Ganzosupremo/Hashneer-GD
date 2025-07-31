class_name SkillTreeMenuTabs extends Control

@onready var skill_tree_button: CustomButton = $PanelContainer/MarginContainer/HBoxContainer/SkillTreeButton
@onready var armory_button: CustomButton = $PanelContainer/MarginContainer/HBoxContainer/ArmoryButton
@onready var visualizer_button: CustomButton = $PanelContainer/MarginContainer/HBoxContainer/VisualizerButton

var _current_scene: Node = null

func switch_tab(scene_enum: SceneManagement.MainScenes) -> void:
	if _current_scene == SceneManager.get_current_scene(): return
	
	_current_scene = SceneManager.get_current_scene()
	
	SceneManager.switch_scene_with_enum(scene_enum)


func _on_skill_tree_button_pressed() -> void:
	switch_tab(SceneManager.MainScenes.SKILL_TREE)


func _on_armory_button_pressed() -> void:
	pass # Replace with function body.


func _on_visualizer_button_pressed() -> void:
	switch_tab(SceneManager.MainScenes.NETWORK_VISUALIZER)
