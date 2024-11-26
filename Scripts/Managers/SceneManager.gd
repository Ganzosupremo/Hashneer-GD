extends Node2D
class_name SceneManagement

signal scene_switched()

var current_level_inde: int = 0
var current_scene = null
var resource_ui = null
var builder_arg: QuadrantBuilderArgs

@onready var background = %ScreenTransitionBackground
@onready var pause_menu = %PauseMenu
@onready var bg = %BG

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	bg.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Return"):
		pause_menu.pause()

func switch_scene_with_packed(sceneto_load: PackedScene) -> void:
	call_deferred("deferred_switch_scene_with_packed", sceneto_load)
#	PersistenceDataManager.save_game()

func deferred_switch_scene_with_packed(sceneto_load: PackedScene) -> void:
	current_scene.free()
	
	background.visible = true
	bg.visible = true
	background.material["shader_parameter/progress"] = 1.0
	
	await tween_bg()
	
	current_scene = sceneto_load.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	background.visible = false
	bg.visible = false
	emit_signal("scene_switched")

func switch_scene(res_path: String, level_index: int = -1):
	if level_index != -1:
		GameManager.current_level_index = level_index
		PersistenceDataManager.save_game()
	call_deferred("deferred_switch_scene", res_path)

func deferred_switch_scene(res_path: String):
	current_scene.free()
	
	bg.visible = true
	background.visible = true
	background.material["shader_parameter/progress"] = 1.0
	var new_scene = ResourceLoader.load(res_path)
	
	await tween_bg()
	
	current_scene = new_scene.instantiate()
	
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	bg.visible = false
	background.visible = false
	emit_signal("scene_switched")

func tween_bg():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		background.material, "shader_parameter/progress", 
		1.0, 1).from(0.0)
	
	await tween.finished
