extends Node2D

var persistence_data_objects: Array = []

func _ready() -> void:
	persistence_data_objects = find_all_persistence_objects()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game(true)

func get_save_path() -> String:
	return "user://saves/"

func find_all_persistence_objects() -> Array:
	return Interface.implementations(get_tree().get_nodes_in_group("PersistentNodes"), IPersistenceData)

func save_game(save_to_disk: bool = false) -> void:
	persistence_data_objects = find_all_persistence_objects()
	var i: int = 0
	for node in persistence_data_objects:
		if Interface.implements(node, IPersistenceData):
			node.save_data()
			print_debug("Nodes Saved: %s" % i)
			i += 1
	
	if save_to_disk:
		SaveSystem.save()

func load_game() -> void:
	persistence_data_objects = find_all_persistence_objects()
	
	for node in persistence_data_objects:
		node.load_data()
