class_name SkillTreeMenuTabsT2 extends Control

@onready var skill_tree_button: CustomButton = $PanelContainer/MarginContainer/HBoxContainer/SkillTreeButton
@onready var armory_button: CustomButton = $PanelContainer/MarginContainer/HBoxContainer/ArmoryButton
@onready var visualizer_button: CustomButton = $PanelContainer/MarginContainer/HBoxContainer/VisualizerButton

@onready var skill_tree: PackedScene = preload("res://Scenes/SkillTreeSystem/SkillTree.tscn")
@onready var network_visualizer: PackedScene = preload("res://Scenes/Miscelaneous/NetworkVisualizer.tscn")

var _current_scene: PackedScene = null

func switch_tab(scene_to_load: PackedScene) -> void:
	_current_scene = scene_to_load
	if _current_scene == null: return
	
	SceneManager.switch_scene_with_packed(scene_to_load)

func _on_skill_tree_button_pressed() -> void:
	switch_tab(skill_tree)

func _on_armory_button_pressed() -> void:
	pass # Replace with function body.

func _on_visualizer_button_pressed() -> void:
	switch_tab(network_visualizer)
