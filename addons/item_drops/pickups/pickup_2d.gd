class_name Pickup2D
extends Area2D
## Represents an object in a 2D scene that can be picked up by a PickupCollector2D, such as one attached to a player character. 
## It tracks a resource and its count to add to an inventory when collected.
## The pickup can be delayed from being collectible using a timer, during which it remains unmonitorable.
##
## Make sure the pickup is either the root or a child of the root object so it can be located

## Emitted when the object is picked up by another node but before the pickup scene is removed from the 2D world.
signal picked_up(data: PickupEvent)

## The bus for handling item drop events.
@export var items_drop_bus: ItemDropsBus

## Scene object root to be freed after pickup.
@export var root: Node

## How many of the pickup's resource is represented by this node.
@export var resource_count: int = 1

## File path to the resource file for the pickup item.
@export_file("*.tres", "*.res") var pickup_resource_file: String

## Whether to automatically free the scene once picked up
## or simply set monitorable false instead and allow animations
## or other scripts to handle freeing the scene instead.
@export var free_on_pickup := true

## The sound to be played on pickup, played through the event since the pickup is freed before the sound finishes.
@export var sound: AudioStream

## Delay in seconds before the pickup becomes monitorable and collectible. If 0 or negative, it’s immediate.
@export var pickup_delay: float = 0.25

var resource_loaded: Resource

func _ready() -> void:
	if validate(): resource_loaded = get_pickup_resource()
	
	if pickup_delay > 0.0:
		set_deferred("monitorable", false)  # Disable detection
		await get_tree().create_timer(pickup_delay).timeout
		set_deferred("monitorable", true)  # Enable detection after delay
	else:
		set_deferred("monitorable", true)  # Ensure it’s enabled if no delay

## Takes the pickup item and removes the scene object.
func take(taker: PickupsCollector2D) -> PickupEvent:
	var event := PickupEvent.new(self, taker)
	picked_up.emit(event)
	items_drop_bus.item_picked.emit(event)
	
	if root != null && free_on_pickup:
		root.queue_free()
	else:
		set.call_deferred("monitorable", false)
	
	return event

## Loads and returns the pickup’s associated resource.
func get_pickup_resource() -> Resource:
	return load(pickup_resource_file)

## Checks required properties to see if the setup is valid. Returns true if no problems are found.
func validate() -> bool:
	var no_problems: bool = true
	if pickup_resource_file.is_empty():
		push_warning("Pickup node '%s' has no pickup_resource_file. No item data available." % name)
		no_problems = false
	return no_problems
