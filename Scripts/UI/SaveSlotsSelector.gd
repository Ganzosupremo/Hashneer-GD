extends Control

const save_text1: String = "SaveOne.sav"
const save_text2: String = "SaveTwo.sav"
const save_text3: String = "SaveThree.sav"

@onready var main_game: PackedScene = preload("res://Scenes/UI/Main_game_ui.tscn")

func _on_slot_button_pressed() -> void:
	SaveSystem.var_file_name = save_text1
	SaveSystem._load()
	if SaveSystem.has_save_file(save_text1):
		PersistenceDataManager.load_gam()
	else: PersistenceDataManager.save_game()
	goto_menu()

func _on_slot_button_2_pressed() -> void:
	SaveSystem.var_file_name = save_text2
	SaveSystem._load()
	if SaveSystem.has_save_file(save_text2):
		PersistenceDataManager.load_gam()
	else: PersistenceDataManager.save_gam()
	goto_menu()

func _on_slot_button_3_pressed() -> void:
	SaveSystem.var_file_name = save_text3
	SaveSystem._load()
	if SaveSystem.has_save_file(save_text3):
		PersistenceDataManager.load_gam()
	else: PersistenceDataManager.save_gam()
	goto_menu()

func goto_menu():
	SceneManager.switch_scene_with_packed(main_game)
