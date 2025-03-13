class_name GatherEvent
extends Object
## Holds information about a gathering event data

## The node being gathered from
var gatherable : Gatherable

## The node which harvested the gatherable node
var gatherer : Gatherer

## Times to gather from the node at once
var times : int

## Array of scene instanced from the gather
var gathered : Array[Node]

func _init(p_gatherable : Gatherable, p_gatherer : Gatherer, p_times : int):
	gatherable = p_gatherable
	gatherer = p_gatherer
	times = p_times
