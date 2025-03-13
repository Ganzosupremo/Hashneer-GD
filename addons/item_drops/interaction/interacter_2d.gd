class_name Interacter2D
extends Area2D
## Add this to an object or character that can try to interact with other game objects that have a 
## Interactable2D area node. They should match on the collision layers if you want this interacter
## to be able to access and interact with the target node

signal targeted_changed(targeted : Interactable2D)

## Root node that this node is attached to. Usually the character or another game object.
@export var root : Node

## All currently known Interactable2D within the InteracterArea2D. The closest
## one will be set as the targeted.
var nearby_interactables : Array[Interactable2D]

## The current targeted Interactable2D is the one that an attempted interaction will attempt
## to interact with when calling the try_interact function
var targeted : Interactable2D :
	set(value):
		if targeted == value:
			return
		
		targeted = value
		targeted_changed.emit(targeted)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

## Tries to call interact on the p_interactable InteractableArea2D
## Returns whether the interaction succeeded or not
func try_interact(p_interactable : Interactable2D = targeted) -> bool:
	if p_interactable == null:
		return false
		
	p_interactable.interaction(self)
	return true

## Gets the closests interactable2D measured by distance of the interactables that are in nearby_interactables
func get_closest() -> Interactable2D:
	var closest_distance : float = INF
	var closest : Interactable2D = null
	
	for interactable in nearby_interactables:
		var distance = global_position.distance_to(interactable.global_position)
		
		if distance < closest_distance:
			closest = interactable
			closest_distance = distance
		
	return closest

func _on_area_entered(p_area : Area2D):
	if p_area is Interactable2D:
		nearby_interactables.append(p_area)
		targeted = get_closest()
	
func _on_area_exited(p_area : Area2D):
	if p_area is Interactable2D:
		nearby_interactables.erase(p_area)
		targeted = get_closest()
