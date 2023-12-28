extends Node2D

const FILE_PATH = "user://saves/"
const FILE_NAME = "save.json"
const RESOURCE_NAME = "NOTASAVEFILENIGGA.tres"

var persistence_data_objects: Array = []
var game_data: GameData = null

func _ready() -> void:
	verify_save_dir(FILE_PATH)
	persistence_data_objects = find_all_persistence_objects()

func find_all_persistence_objects() -> Array:
	return Interface.implementations(get_tree().get_nodes_in_group("PersistentNodes"), IPersistenceData)

func verify_save_dir(path: String):
	DirAccess.make_dir_absolute(path)

func new_game() -> void:
	game_data = GameData.new()

func save_game() -> void:
	if game_data == null:
		print("Game Data is null, a new game will be started")
		new_game()
	
	var full_path: String = FILE_PATH + RESOURCE_NAME
	persistence_data_objects = find_all_persistence_objects()
	
	for node in persistence_data_objects:
		if Interface.implements(node, IPersistenceData):
			node.save_data(game_data)
	
	game_data.last_updated = var_to_bytes(Time.get_datetime_string_from_system(false,true))
	
	save_resource(game_data, full_path)

func save_resource(game_data: GameData, full_path: String):
	ResourceSaver.save(game_data, full_path)


## Incomplete function
func save(data: Dictionary) -> void:
	var full_path: String = FILE_PATH + FILE_NAME
	
	var game_saved = FileAccess.open(full_path, FileAccess.WRITE)
	if game_saved == null: 
		print(FileAccess.get_open_error())
		return
	
	var json_string = JSON.stringify(data, "\t")
	game_saved.store_line(json_string)
	game_saved.close()

func load_game() -> void:
	if game_data == null:
		print("Game Data is null, a new game will be started")
		new_game()
		return
	
	game_data = load_resource()
	
	if game_data == null:
		print("No data to load found, a new game needs to be started...")
		new_game()
		return
	
	persistence_data_objects = find_all_persistence_objects()
	
	for node in persistence_data_objects:
		node.load_data(game_data)

func load_resource() -> GameData:
	var full_path: String = FILE_PATH + RESOURCE_NAME
	var res: GameData = load(full_path) as GameData	
	if !res:
		res = GameData.new()

	return res

## Incomplete function
func load_data() -> Dictionary:
	if !FileAccess.file_exists(FILE_PATH + FILE_NAME): return {}
	
	var full_path: String = FILE_PATH + FILE_NAME
	var game_saved = FileAccess.open(full_path, FileAccess.READ)
	var data = null
	while game_saved.get_position() < game_saved.get_length():
		var json_string = game_saved.get_line()
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		
		if parse_result != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			return {}
		
		data = json.get_data()
	return data
