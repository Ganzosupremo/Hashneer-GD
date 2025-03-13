class_name SpawnEvent
extends Object

## Where the spawned object is considered to have come form
var spawner : Node

## The spawned object
var spawned : Node

func _init(p_spawner : Node, p_spawned : Node):
	spawner = p_spawner
	spawned = p_spawned
