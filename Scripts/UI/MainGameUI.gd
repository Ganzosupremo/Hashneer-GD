extends Control
class_name MainGameUI

@onready var level_picker_scene: PackedScene = preload("res://Scenes/UI/Levels_selector.tscn")
@onready var shop_scene: PackedScene = preload("res://Scenes/SkillTreeSystem/Skill_tree.tscn")

func _on_start_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(level_picker_scene)

func _on_skill_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(shop_scene)
