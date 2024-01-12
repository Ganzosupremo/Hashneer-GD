extends Control

@onready var skill_tree: PackedScene = preload("res://Scenes/SkillTreeSystem/Skill_tree.tscn")
@onready var network_scene: PackedScene = preload("res://Scenes/Miscelaneous/network_visualizer.tscn")


func _on_skill_tree_pressed() -> void:
	SceneManager.switch_scene_with_packed(skill_tree)


func _on_network_pressed() -> void:
	SceneManager.switch_scene_with_packed(network_scene)
