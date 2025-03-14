class_name PickupEvent
extends Object
## Occurance data for an item being successfully picked up from the game scene

## The object being picked up
var pickup : Pickup2D

## The object picking up the node
var collector : Object

func _init(p_pickup : Pickup2D, p_collector : Object):
	pickup = p_pickup
	collector = p_collector
