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

## Screens of the hub (between runs) that the top navigation bar switches between, in tab order.
const HUB_SCENES: Array[MainScenes] = [MainScenes.SKILL_TREE, MainScenes.ARMORY, MainScenes.NETWORK_VISUALIZER]

## Transition length for regular scene changes and for hops between hub screens.
const TRANSITION_TIME: float = 0.6
const HUB_TRANSITION_TIME: float = 0.3

var current_scene: Node = null
## True while a scene change is in progress. Extra requests are ignored until it ends,
## so double clicks can't free the same scene twice.
var is_switching: bool = false
var _transition_time: float = TRANSITION_TIME

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
	bg.visible = false
	# Autoloads are ready before the main scene is added, so pick it up at the end of the frame
	_pick_up_startup_scene.call_deferred()

func _pick_up_startup_scene() -> void:
	if current_scene != null: return
	current_scene = get_tree().current_scene
	if current_scene == null:
		var root = get_tree().root
		current_scene = root.get_child(root.get_child_count() - 1)

func switch_scene_with_enum(scene_enum: MainScenes) -> void:
	if scene_enum in main_scenes:
		switch_scene_with_packed(main_scenes[scene_enum])
	else:
		push_error("Invalid scene enum provided: %s" % scene_enum)

func switch_scene_with_packed(sceneto_load: PackedScene) -> void:
	if is_switching: return
	is_switching = true
	call_deferred("_deferred_switch_scene_with_packed", sceneto_load)

## Opens one of the [constant HUB_SCENES] with the short transition.
## Does nothing if that screen is already open or another change is running.
## Returns false when the request was ignored.
func go_to_hub(scene_enum: MainScenes) -> bool:
	if is_switching or get_current_scene_enum() == scene_enum: return false
	_transition_time = HUB_TRANSITION_TIME if is_hub_scene(get_current_scene_enum()) else TRANSITION_TIME
	switch_scene_with_enum(scene_enum)
	return true

func is_hub_scene(scene_enum: int) -> bool:
	return scene_enum in HUB_SCENES

## Which [enum MainScenes] is open right now, or -1 if the current scene isn't one of them.
func get_current_scene_enum() -> int:
	return get_scene_enum(current_scene)

## Which [enum MainScenes] [param scene_root] was instanced from, or -1.
func get_scene_enum(scene_root: Node) -> int:
	if scene_root == null or not is_instance_valid(scene_root): return -1
	var path: String = scene_root.scene_file_path
	if path.is_empty(): return -1
	for key in main_scenes:
		if main_scenes[key].resource_path == path:
			return key
	return -1

func get_current_scene() -> Node:
	if current_scene:
		return current_scene
	else:
		push_error("No current scene set.")
		return null


func _deferred_switch_scene_with_packed(scene_to_load: PackedScene) -> void:
	# Keep purchases made in this scene, the next scene reloads every system from the save data
	PersistenceDataManager.save_game()
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
	_transition_time = TRANSITION_TIME
	is_switching = false
	scene_switched.emit()

func switch_scene(res_path: String):
	if is_switching: return
	is_switching = true
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
	is_switching = false
	scene_switched.emit()

func _tween_bg():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		screen_transition_background.material, "shader_parameter/progress", 
		1.0, _transition_time).from(0.0)
	await tween.finished
