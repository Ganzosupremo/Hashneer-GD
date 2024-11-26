extends Control

@onready var skill_tree: PackedScene = preload("res://Scenes/SkillTreeSystem/Skill_tree.tscn")

func _on_skill_tree_pressed() -> void:
	SceneManager.switch_scene_with_packed(skill_tree)
