extends Control

@onready var network_layer: ColorRect = $Background/NetworkLayer

@onready var slot_button_1: Button = %SlotButton1
@onready var slot_button_2: Button = %SlotButton2
@onready var slot_button_3: Button = %SlotButton3
@onready var back_button: Button = %BackButton

const save_text1: String = "SaveOne.sav"
const save_text2: String = "SaveTwo.sav"
const save_text3: String = "SaveThree.sav"

var time_passed: float = 0.0

func _ready() -> void:
	back_button.text = "RETURN TO MAIN MENU"
	# Add fade-in animation
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.8)
	
	# Update slot button texts based on save file existence
	_update_slot_texts()
	
	# Focus first slot
	slot_button_1.grab_focus()

func _update_slot_texts() -> void:
	slot_button_1.text = "SLOT 01\n" + (_get_save_status(save_text1))
	slot_button_2.text = "SLOT 02\n" + (_get_save_status(save_text2))
	slot_button_3.text = "SLOT 03\n" + (_get_save_status(save_text3))

func _get_save_status(file_name: String) -> String:
	if SaveSystem.has_save_file(file_name):
		return "SAVE FOUND // CONTINUE"
	else:
		return "EMPTY // NEW RUN"

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
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.MAIN_MENU)

func _load_save_file(file_name: String) -> void:
	PersistenceDataManager.select_slot(file_name)
