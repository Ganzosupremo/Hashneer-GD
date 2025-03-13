class_name InventoryDrop
extends Node
## Drops items from an inventory into the game world

## When true, calling drop will place all items in the inventory to the game world and
## remove it from the inventory
@export var drop_all = true

## Used if drop all is not checked to determine how many items to drop from the inventory
@export_range(1, 100, 1, "or_greater") var drop_count : int = 1

## The inventory
@export var inventory : Node

## SceneSpawner2D or SceneSpawner3D to place scenes into the game world to represent the dropped items, possibly as a pickup item
@export var scene_spawner : Node

## Settings to define what methods get called to access and remove items from a system agnostic inventory
@export var access : InventoryAccessSettings

var rng = RandomNumberGenerator.new()

## Drops items from an inventory node and places them in the game world
## [br][br]
## Returns the array of placed game scene roots
func drop() -> Array[Node]:
	var results : Array = inventory.call(access.method_get_contents)
	var items : Array = results.duplicate()
	
	if not drop_all:
		items = select_random_items(items, drop_count)
	
	var scenes : Array[PackedScene] = get_scenes(items)
	var instances : Array[Node] = []
	
	for scene in scenes:
		var spawned = scene_spawner.spawn(scene)
		instances.append(spawned)
	
	remove_items_from_inventory(items)
	
	return instances

## Returns a random select from the p_possible array of items
func select_random_items(p_possible : Array, p_desired : int) -> Array:
	var remaining = p_possible.duplicate()
	var selected : Array = []
	
	## Select until p_desired count is reached in selected array or remaining is empty
	while selected.size() < p_desired && remaining.size() > 0:
		var selection_idx : int = rng.randi_range(0, remaining.size() - 1)
		var next_item = remaining[selection_idx]
		selected.append(next_item)
		remaining.erase(next_item)
	
	return selected

## Loads scenes using the access.path_to_scene_path array to locate the
## final property where the scene_path string is stored for the item type.
func get_scenes(p_items : Array):
	var scenes : Array[PackedScene] = []
	
	for item in p_items:
		
		## The current property value as it navigates to lower level properties.
		## Should be the scene_path after the for loop is done
		var next = item
		var levels_reached = 0
		
		## Call get on properties until reaching the actual item scene_path property
		for prop in access.path_to_scene_path:
			var found_value = next.get(prop)
			
			if found_value == null:
				break # Failed to access the property at this level
				
			next = found_value
			levels_reached += 1
		
		if levels_reached != access.path_to_scene_path.size():
			break # It failed to find the actual scene_path of the item
		
		var scene : PackedScene = load(next)
		scenes.append(scene)

	return scenes

## Removes an array of items (arbitarily defined, this could be a stack or actual item resource.) from the inventory
## by calling the access.method_remove method
## [br][br]
## Returns the number of items removed
func remove_items_from_inventory(p_items : Array) -> int:
	var removed : int = 0
	
	for item in p_items:
		inventory.call(access.method_remove, item)
		removed += 1

	return removed
