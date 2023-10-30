extends Node2D
class_name LevelsManager

var current_level_index: int = 0
var current_scene = null
var resource_ui = null
var hide_ui: bool = false


@onready var loading_screen: PackedScene = preload("res://Scenes/UI/Loading_screen.tscn")
@onready var resource_ui_scene: PackedScene = preload("res://Scenes/UI/currency_ui.tscn")
@onready var background = %ScreenTransitionBackground
@onready var pause_menu = %PauseMenu
@onready var bg = %BG

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	bg.visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Return"):
		pause_menu.pause()

## Loads the specified scene, it uses and index to load a scene dinamycally
##so the res_path should only be the ("res://Scenes/Level) and then the method builds the rest of the scene
## with the index
func switchto_level_scene(res_path: String, scene_index: int) -> void:
	call_deferred("deferred_switchto_level_scene", res_path, scene_index)

func deferred_switchto_level_scene(res_path: String, scene_index: int) -> void:
	current_scene.free()
	bg.visible = true	
	background.visible = true
	background.material["shader_parameter/progress"] = 1.0
	
	await  init_tween()
	
	current_level_index = scene_index
	var new_res_path: String = res_path + str(current_level_index) + ".tscn"
	
	var new_scene = ResourceLoader.load(new_res_path)
	current_scene = new_scene.instantiate()
	
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	background.visible = false
	bg.visible = false

func switch_scene(res_path: String):
	call_deferred("deferred_switch_scene", res_path)

func deferred_switch_scene(res_path: String):
	current_scene.free()
	
	background.visible = true
	background.material["shader_parameter/progress"] = 1.0
	
	await init_tween()
	
	var new_scene = ResourceLoader.load(res_path)
	current_scene = new_scene.instantiate()
	
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	background.visible = false

func init_tween():
	var tween = create_tween()
	tween.tween_property(
		background.material, "shader_parameter/progress", 
		1.0, 1).from(0.0).set_trans(Tween.TRANS_SINE)
	
	await tween.finished

func toggle_main_ui():
	if resource_ui == null:
		resource_ui = resource_ui_scene.instantiate()
		add_child(resource_ui)
	
	if hide_ui:
		resource_ui.hide()
	else:
		resource_ui.show()
	hide_ui = !hide_ui

