extends Node2D

var persistence_data_objects: Array = []

func _ready() -> void:
	persistence_data_objects = find_all_persistence_objects()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("game saved!")
		save_game(true)

func find_all_persistence_objects() -> Array:
	return Interface.implementations(get_tree().get_nodes_in_group("PersistentNodes"), IPersistenceData)

func save_game(save_to_disk: bool = false) -> void:
	persistence_data_objects = find_all_persistence_objects()
	var i: int = 0
	for node in persistence_data_objects:
		if Interface.implements(node, IPersistenceData):
			node.save_data()
			print("nodes saved: %s" % i)
			i += 1
	
	if save_to_disk:
		SaveSystem.save()

func _save_resource(game_data: GameData, full_path: String):
	SaveSystem.set_var("game_data", game_data)

## Incomplete function
#func _save(data: Dictionary) -> void:	
#	var game_saved = FileAccess.open(full_path, FileAccess.WRITE)
#	if game_saved == null: 
#		print(FileAccess.get_open_error())
#		return
#
#	var json_string = JSON.stringify(data, "\t")
#	game_saved.store_line(json_string)
#	game_saved.close()

func load_gam() -> void:	
	persistence_data_objects = find_all_persistence_objects()
	
	for node in persistence_data_objects:
		node.load_data()

## Incomplete function
#func _load_data() -> Dictionary:
#	if !FileAccess.file_exists(FILE_PATH + FILE_NAME): return {}
#
#	var full_path: String = FILE_PATH + FILE_NAME
#	var game_saved = FileAccess.open(full_path, FileAccess.READ)
#	var data = null
#	while game_saved.get_position() < game_saved.get_length():
#		var json_string = game_saved.get_line()
#		var json = JSON.new()
#
#		var parse_result = json.parse(json_string)
#
#		if parse_result != OK:
#			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
#			return {}
#
#		data = json.get_data()
#	return data
