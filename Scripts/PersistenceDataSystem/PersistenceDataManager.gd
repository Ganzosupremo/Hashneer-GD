extends Node2D

## Command line argument used to open a save slot right after a restart, see [method select_slot].
const SLOT_ARGUMENT: String = "--slot="

var persistence_data_objects: Array = []
## The save slot loaded in this session, empty until the player picks one.
var _current_slot: String = ""

func _ready() -> void:
	persistence_data_objects = find_all_persistence_objects()
	var slot: String = _get_slot_from_arguments()
	if !slot.is_empty():
		# Deferred so every autoload and the main scene are ready first
		select_slot.call_deferred(slot)

## Opens the given save slot and goes to the skill tree.[br]
## The autoloads and the shared upgrade resources keep the state of the slot loaded first, so
## switching to another slot in the same session would mix both saves. In that case the current
## slot is saved and the game restarts straight into the new slot.
func select_slot(file_name: String) -> void:
	if !_current_slot.is_empty() and _current_slot != file_name:
		save_game(true)
		_restart_with_slot(file_name)
		return

	if _current_slot.is_empty():
		_current_slot = file_name
		SaveSystem.var_file_name = file_name
		if SaveSystem.has_save_file(file_name):
			load_game(true)
		else:
			save_game(true)
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.SKILL_TREE)

func _restart_with_slot(file_name: String) -> void:
	var arguments: PackedStringArray = []
	# Engine arguments aren't listed in get_cmdline_args(), these are needed to restart the same way
	if !OS.has_feature("template"):
		# Running from the editor binary, it needs to know which project to open
		arguments.append_array(["--path", ProjectSettings.globalize_path("res://")])
	if DisplayServer.get_name() == "headless":
		arguments.append("--headless")
	for argument in OS.get_cmdline_args():
		if !argument.begins_with(SLOT_ARGUMENT):
			arguments.append(argument)
	arguments.append(SLOT_ARGUMENT + file_name)
	OS.set_restart_on_exit(true, arguments)
	get_tree().quit()

func _get_slot_from_arguments() -> String:
	for argument in OS.get_cmdline_args():
		if argument.begins_with(SLOT_ARGUMENT):
			return argument.trim_prefix(SLOT_ARGUMENT)
	return ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game(true)

func get_save_path() -> String:
	return "user://saves/"

func find_all_persistence_objects() -> Array:
	return Interface.implementations(get_tree().get_nodes_in_group("PersistentNodes"), IPersistenceData)

func save_game(save_to_disk: bool = false) -> void:
	persistence_data_objects = find_all_persistence_objects()

	for node in persistence_data_objects:
		if Interface.implements(node, IPersistenceData):
			node.save_data()
	
	if save_to_disk:
		SaveSystem.save()

func load_game(initial_load:bool = false) -> void:
	if initial_load:
		SaveSystem.load()
	
	persistence_data_objects = find_all_persistence_objects()
	
	for node in persistence_data_objects:
		if Interface.implements(node, IPersistenceData):
			node.load_data()
