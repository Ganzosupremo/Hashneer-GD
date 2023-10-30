extends Control

var current_scene_index: int = 0
const PARTIAL_SCENE_PATH: String = "res://Scenes/Levels/Level"
var test: int = 0
func _on_button_level_1_pressed() -> void:
	current_scene_index = 0
	call_switch_scene(PARTIAL_SCENE_PATH, current_scene_index)


func _on_button_level_2_pressed() -> void:
	current_scene_index = 1
	call_switch_scene(PARTIAL_SCENE_PATH, current_scene_index)


func _on_button_level_3_pressed() -> void:
	current_scene_index = 2
	call_switch_scene(PARTIAL_SCENE_PATH, current_scene_index)


func _on_button_level_4_pressed() -> void:
	current_scene_index = 3
	call_switch_scene(PARTIAL_SCENE_PATH, current_scene_index)


func _on_button_level_5_pressed() -> void:
	current_scene_index = 4
	call_switch_scene(PARTIAL_SCENE_PATH, current_scene_index)


func _on_button_level_6_pressed() -> void:
	current_scene_index = 5
	call_switch_scene(PARTIAL_SCENE_PATH, current_scene_index)


func _on_button_level_7_pressed() -> void:
	current_scene_index = 6
	call_switch_scene(PARTIAL_SCENE_PATH, current_scene_index)


func _on_button_level_8_pressed() -> void:
	var total_reward: float = 21000000
	var num_distribute = 21
	
	var first_person_reward = total_reward / (2 * (1 - pow(0.5, num_distribute)))
	
	var current_reward = first_person_reward
	var distributed_total = 0.0
	
	for i in range(num_distribute):
		print("Person %d gets: %f units" % [i+1, current_reward])
		distributed_total += current_reward
		current_reward *= 0.5  # Halve the reward for the next person
	
	print("Total distributed: %f units" % distributed_total)


func _on_button_level_9_pressed() -> void:
	print(BitcoinNetwork.issue_coins(test) + test)
	test += 1


func _on_button_level_10_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_11_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_12_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_13_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_14_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_15_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_16_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_17_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_18_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_19_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_20_pressed() -> void:
	pass # Replace with function body.


func _on_button_level_21_pressed() -> void:
	pass # Replace with function body.

func call_switch_scene(res_path: String, scene_index: int):
	await SceneManager.switchto_level_scene(res_path, scene_index)
	SceneManager.toggle_main_ui()
