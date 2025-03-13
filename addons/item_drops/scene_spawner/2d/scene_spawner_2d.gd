class_name SceneSpawner2D
extends Node2D
## A scene spanwer intended to instantiate 2D objects
## into 2D game scenes

## Should be emitted whenever the spanwer spawns a scene
signal spawned(event : SpawnEvent)

## Name of the group that holds the node that will be parent to all scenes spawned by this spawner
@export var spawn_group : SpawnGroup

var spawn_parent : Node :
	get():
		if spawn_parent == null:
			spawn_parent = locate_spawn_parent()
		
		return spawn_parent

func _ready():
	var has_group : bool = get_tree().has_group(spawn_group.name)
	
	if has_group:
		spawn_parent = locate_spawn_parent()
	
	_validate()
	spawned.connect(_on_spawned)
	
## Spawns a scene into the game world
func spawn(p_packed_scene : PackedScene) -> Node:
	var instance = p_packed_scene.instantiate()
	var global_spawn_position = get_spawn_position()
	spawn_parent.add_child.call_deferred(instance, true)
	instance.call_deferred("set_global_position", global_spawn_position)
	
	## Send signal after adding child to tree
	var event = SpawnEvent.new(self, instance)
	call_deferred("emit_signal", "spawned", event)
	
	return instance

## Execute any code needed on the instanced object after it's placed into the game world here
func post_spawn(event : SpawnEvent):
	pass

## Gets the spawn position for the instanced object
func get_spawn_position():
	push_error("Virtual method. Implement in child class")
	return null

## Grabs the first node in the spawn parent group to be the parent of spawned nodes
func locate_spawn_parent():
	var group_nodes = get_tree().get_nodes_in_group(spawn_group.name)
	
	if group_nodes:
		return group_nodes[0]

func _validate() -> bool:
	var no_problems = true
	
	if spawn_group == null:
		push_warning("No spawn group set on %s. It won't be able to properly instantiate objects under the parent group node." % get_path())
		no_problems = false
	
	if spawn_parent == null:
		push_warning("No spawn parent node found with the group name '%s'." % spawn_group.name)
		no_problems = false
		
	return no_problems
	
func _on_spawned(event : SpawnEvent):
	post_spawn(event)
