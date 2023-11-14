extends Control
class_name SkillsTree

const FILE_PATH = "user://saves/"
const FILE_NAME = "save.json"


@onready var skill_info_window: SkillInfoWindow = %SkillInfoWindow
@onready var bg = %BG
var skill_nodes_list: Array = []
var node_ids: Dictionary = {}

func _ready() -> void:
	for skill_node in bg.get_children():
		add_child_to_list(skill_node)
		
#	var node_ids: Dictionary = {}
	for skill_node in bg.get_children():
		if node_ids.has(skill_node.upgrade_data.id):
			print("ERROR: Duplicated ID")
			continue
		else:
			node_ids[skill_node.upgrade_data.id] = skill_node
	
#	for skill_node in bg.get_children():
#		for id in skill_node.children_nodes_ids:
#			skill_node.children_nodes_ids[id] = node_ids[id]
 
func show_skill_info_window(skill_node: SkillNode):
	skill_info_window.set_info_window(skill_node)

func hide_skill_info_window():
	skill_info_window.hide_info_window()

func add_child_to_list(child: SkillNode):
	skill_nodes_list.append(child)

func _on_save_button_pressed() -> void:
	DirAccess.make_dir_absolute(FILE_PATH)
	var save_game = FileAccess.open(FILE_PATH + FILE_NAME, FileAccess.WRITE)
	if save_game == null: 
		print(save_game.get_open_error())
		return
	
	var save_nodes = get_tree().get_nodes_in_group("PersistentNodes")
	for node in save_nodes:
		print(node)
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue
		var node_data = node.save()
		
		var json_string = JSON.stringify(node_data, "\t")
		# Store the save dictionary as a new line in the save file.
		save_game.store_line(json_string)
		save_game.close()

func _on_main_menu_button_pressed() -> void:
	SceneManager.switch_scene("res://Scenes/UI/Main_game_ui.tscn")
