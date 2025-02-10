extends Control

@onready var container: GridContainer = %Grid
@onready var main_menu_scene: PackedScene = load("res://Scenes/UI/Main_menu.tscn")
@onready var skill_tree_scene: PackedScene = load("res://Scenes/SkillTreeSystem/SkillTree.tscn")
@onready var level_one: LevelSelectorButton = $ScrollContainer/Grid/LevelSelectorButton



var children: Array

func _ready() -> void:
	level_one.grab_focus()
	children = container.get_children()
	for i in children.size():
		children[i].level_index = i
		children[i].init_builder_args()
		if !GameManager.game_levels.has(children[i].builder_args):
			GameManager.game_levels.append(children[i].builder_args)
	disable_levels()

func disable_levels() -> void:
	for button in children:
		# the first level is unlocked by default
		if button.level_index == 0:
			button.disabled = false
			continue
			
		# unlock the levels in the range
		if button.level_index in range(GameManager.levels_unlocked):
			button.text = str(button.level_index)
			continue
		
		button.text = str(button.level_index)
		button.disabled = true

func _on_skill_tree_pressed() -> void:
	SceneManager.switch_scene_with_packed(skill_tree_scene)


func _on_menu_pressed() -> void:
	SceneManager.switch_scene_with_packed(main_menu_scene)
