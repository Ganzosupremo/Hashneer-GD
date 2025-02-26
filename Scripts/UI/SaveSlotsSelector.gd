extends Control

@onready var main_game: PackedScene = preload("res://Scenes/SkillTreeSystem/SkillTree.tscn")

const save_text1: String = "SaveOne.sav"
const save_text2: String = "SaveTwo.sav"
const save_text3: String = "SaveThree.sav"

func _on_slot_button_pressed() -> void:
	_load_save_file(save_text1)

func _on_slot_button_2_pressed() -> void:
	_load_save_file(save_text2)

func _on_slot_button_3_pressed() -> void:
	_load_save_file(save_text3)

func _load_save_file(file_name: String) -> void:
	SaveSystem.var_file_name = file_name
	if SaveSystem.has_save_file(file_name):
		PersistenceDataManager.load_game(true)
	else:
		PersistenceDataManager.save_game(true)
	go_to_menu()

func go_to_menu():
	SceneManager.switch_scene_with_packed(main_game)
