class_name PickupsCollector2D
extends Area2D
## Enables a scene to collect objects with a Pickup2D area from the game world when they enter this trigger area. 
## Collected items are added to a specified inventory, which must implement an add_to_inventory method (see access : InventoryAccessSettings). 
## Supports audio playback for pickup sounds and configurable inventory access settings.

## Emitted when a pickup is successfully collected, carrying details of the event.
signal picked_up(pickup: PickupEvent)

## The node performing the pickup action on behalf of this collector.
@export var actor: Node

## The node holding a reference to the inventory node or resource.
@export var inventory_node: Node

## Settings for accessing the inventory, including method and property names.
@export var access: InventoryAccessSettings

## Audio player for playing pickup sound effects.
@export var sound_player: AudioStreamPlayer2D

var inventory: Object  # The resolved inventory object

func _ready() -> void:
	inventory = locate_inventory()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

## Handles pickup detection when an area enters the trigger.
func _on_area_entered(area: Area2D) -> void:
	var pickup := find_pickup(area)
	if pickup:
		try_pick_up(pickup)

## Handles pickup detection when a body enters the trigger.
func _on_body_entered(body: Node2D) -> void:
	var pickup := find_pickup(body)
	if pickup:
		try_pick_up(pickup)

## Searches for a Pickup2D component within a given root node or its children.
func find_pickup(root_node: Node2D) -> Pickup2D:
	if root_node is Pickup2D:
		return root_node
	for pickup_child in root_node.get_children():
		if pickup_child is Pickup2D:
			return pickup_child
	return null

## Attempts to collect a pickup and add its resource to the inventory.
## Returns true if the pickup was successfully collected, false otherwise.
func try_pick_up(pickup: Pickup2D) -> bool:
	var resource := pickup.get_pickup_resource()
	if inventory == null: 
		inventory = locate_inventory() # Ensure inventory is found
		if inventory == null: return false
		
	var results = inventory.call(access.method_add, resource, pickup.resource_count)
	
	if _was_add_to_inventory_successful(results):
		var data := pickup.take(self)
		if not data:  # Pickup might be delayed or unavailable
			return false
		
		picked_up.emit(data)
		
		if sound_player and data.pickup.sound:
			sound_player.stream = data.pickup.sound
			sound_player.play()
		
		return true
	return false

## Locates the inventory object using the inventory node and access settings.
func locate_inventory() -> Object:
	var found: Object
	if access.prop_inventory.is_empty():
		found = inventory_node
	else:
		found = inventory_node.get(access.prop_inventory)
	
	if not found:
		push_error("No inventory located for PickupsCollector2D at %s" % get_path())
	
	return found

## Determines if the inventory add operation was successful based on the result type.
func _was_add_to_inventory_successful(results) -> bool:
	match typeof(results):
		TYPE_BOOL:
			return results
		TYPE_INT:
			return results >= 1
		TYPE_FLOAT:
			return results >= 1
		TYPE_NIL:
			return true  # Assume success if no result is returned
		TYPE_ARRAY:
			return results.size() > 0
		_:
			push_error("Unsupported inventory result type: %s" % typeof(results))
			return false
