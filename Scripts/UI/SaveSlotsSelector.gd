extends Control

@onready var main_game: PackedScene = preload("res://Scenes/SkillTreeSystem/SkillTree.tscn")
@onready var main_menu: String = "res://Scenes/UI/MainMenu.tscn"
@onready var network_layer: ColorRect = $Background/NetworkLayer

@onready var slot_button_1: Button = %SlotButton1
@onready var slot_button_2: Button = %SlotButton2
@onready var slot_button_3: Button = %SlotButton3

const save_text1: String = "SaveOne.sav"
const save_text2: String = "SaveTwo.sav"
const save_text3: String = "SaveThree.sav"

var time_passed: float = 0.0

func _ready() -> void:
	# Add fade-in animation
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.8)
	
	# Update slot button texts based on save file existence
	_update_slot_texts()
	
	# Focus first slot
	slot_button_1.grab_focus()

func _update_slot_texts() -> void:
	slot_button_1.text = "Slot 1\n" + (_get_save_status(save_text1))
	slot_button_2.text = "Slot 2\n" + (_get_save_status(save_text2))
	slot_button_3.text = "Slot 3\n" + (_get_save_status(save_text3))

func _get_save_status(file_name: String) -> String:
	if SaveSystem.has_save_file(file_name):
		return "[Continue]"
	else:
		return "[New Game]"

func _on_animation_timer_timeout() -> void:
	time_passed += 0.016
	if network_layer and network_layer.material:
		network_layer.material.set_shader_parameter("time", time_passed)

func _on_slot_button_pressed() -> void:
	_load_save_file(save_text1)

func _on_slot_button_2_pressed() -> void:
	_load_save_file(save_text2)

func _on_slot_button_3_pressed() -> void:
	_load_save_file(save_text3)

func _on_back_button_pressed() -> void:
	SceneManager.switch_scene(main_menu)

func _load_save_file(file_name: String) -> void:
	SaveSystem.var_file_name = file_name
	if SaveSystem.has_save_file(file_name):
		PersistenceDataManager.load_game(true)
	else:
		PersistenceDataManager.save_game(true)
	go_to_menu()

func go_to_menu():
	SceneManager.switch_scene_with_packed(main_game)
