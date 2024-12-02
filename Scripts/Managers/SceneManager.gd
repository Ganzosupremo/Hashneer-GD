extends Node2D
class_name SceneManagement

signal scene_switched()

var current_level_inde: int = 0
var current_scene: Node = null

@onready var screen_transition_background = %ScreenTransitionBackground
@onready var bg = %BG

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	bg.visible = false

func switch_scene_with_packed(sceneto_load: PackedScene) -> void:
	await get_tree().process_frame
	call_deferred("_deferred_switch_scene_with_packed", sceneto_load)

func _alt_deferred_switch_scene_with_packed(scene_to_load: PackedScene) -> void:
	pass


func _deferred_switch_scene_with_packed(scene_to_load: PackedScene) -> void:
	#current_scene.queue_free()
	
	screen_transition_background.visible = true
	bg.visible = true
	screen_transition_background.material["shader_parameter/progress"] = 1.0
	
	await _tween_bg()
	
	get_tree().change_scene_to_packed(scene_to_load)
	
	#current_scene = scene_to_load.instantiate()
	#get_tree().root.add_child(current_scene)
	#get_tree().current_scene = current_scene
	screen_transition_background.visible = false
	bg.visible = false
	scene_switched.emit()

func switch_scene(res_path: String, level_index: int = -1):
	if level_index != -1:
		GameManager.current_level_index = level_index
		PersistenceDataManager.save_game()
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
		1.0, 0.8).from(0.0)
	await tween.finished
