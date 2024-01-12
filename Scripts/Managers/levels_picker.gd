extends Control

@onready var container: GridContainer = %Grid
@onready var main_menu_scene: PackedScene = preload("res://Scenes/UI/Main_game_ui.tscn")
@onready var shop_scene: PackedScene = preload("res://Scenes/SkillTreeSystem/Skill_tree.tscn")

var children: Array

func _ready() -> void:
	children = container.get_children()
	for i in container.get_child_count():
		children[i].level_index = i
		children[i].init_builder_args()
		if !GameManager.game_levels.has(i+1):
			GameManager.game_levels.append(i+1)
	disable_levels()

func disable_levels() -> void:
	for button in container.get_children():
		if button.level_index in range(GameManager.levels_unlocked):
			continue
		
		button.text = str(button.level_index)
		button.disabled = true

func _on_menu_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(main_menu_scene)

func _on_shop_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(shop_scene)
