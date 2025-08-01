extends Node2D
class_name SceneManagement

signal scene_switched()

enum MainScenes {
	MAIN_MENU,
	SAVE_SLOTS_SELECTOR,
	SKILL_TREE,
	ARMORY,
	NETWORK_VISUALIZER,
	MINING_GAME_MODE,
	UNLIMITED_WAVES_GAME_MODE
}

var current_scene: Node = null

@onready var screen_transition_background = %ScreenTransitionBackground
@onready var bg = %BG

var main_scenes: Dictionary = {
	MainScenes.MAIN_MENU: preload("res://Scenes/UI/MainMenu.tscn"),
	MainScenes.SAVE_SLOTS_SELECTOR: preload("res://Scenes/UI/SaveSlotsSelector.tscn"),
	MainScenes.SKILL_TREE: preload("res://Scenes/SkillTreeSystem/SkillTree.tscn"),
	MainScenes.ARMORY: preload("res://Scenes/UI/ArmoryUI.tscn"),
	MainScenes.NETWORK_VISUALIZER: preload("res://Scenes/Miscelaneous/NetworkVisualizer.tscn"),
	MainScenes.MINING_GAME_MODE: preload("res://Scenes/GameModes/MiningGameMode.tscn"),
	MainScenes.UNLIMITED_WAVES_GAME_MODE: preload("res://Scenes/GameModes/UnlimitedWavesGameMode.tscn")
}

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	bg.visible = false

func switch_scene_with_enum(scene_enum: MainScenes) -> void:
	if scene_enum in main_scenes:
		switch_scene_with_packed(main_scenes[scene_enum])
	else:
		push_error("Invalid scene enum provided: %s" % scene_enum)

func switch_scene_with_packed(sceneto_load: PackedScene) -> void:
	call_deferred("_deferred_switch_scene_with_packed", sceneto_load)

func get_current_scene() -> Node:
	if current_scene:
		return current_scene
	else:
		push_error("No current scene set.")
		return null


func _deferred_switch_scene_with_packed(scene_to_load: PackedScene) -> void:
	current_scene.free()
	
	screen_transition_background.visible = true
	bg.visible = true
	screen_transition_background.material["shader_parameter/progress"] = 0.0
	
	await _tween_bg()
	
	current_scene = scene_to_load.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	screen_transition_background.visible = false
	bg.visible = false
	scene_switched.emit()

func switch_scene(res_path: String):
	call_deferred("_deferred_switch_scene", res_path)

func _deferred_switch_scene(res_path: String):
	current_scene.queue_free()
	
	bg.visible = true
	screen_transition_background.visible = true
	screen_transition_background.material["shader_parameter/progress"] = 1.0
	var new_scene = ResourceLoader.load(res_path)
	
	await _tween_bg()
	
	current_scene = new_scene.instantiate()
	
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	bg.visible = false
	screen_transition_background.visible = false
	scene_switched.emit()

func _tween_bg():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		screen_transition_background.material, "shader_parameter/progress", 
		1.0, 0.6).from(0.0)
	await tween.finished
