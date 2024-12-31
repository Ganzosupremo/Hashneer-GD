extends Control
class_name MainGameUI

@onready var level_picker_scene: PackedScene = load("res://Scenes/UI/Levels_selector.tscn")
@onready var skill_tree_scene: PackedScene = load("res://Scenes/SkillTreeSystem/SkillTree.tscn")

func _on_start_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(level_picker_scene)

func _on_skill_button_pressed() -> void:
	PersistenceDataManager.load_game()
	SceneManager.switch_scene_with_packed(skill_tree_scene)
