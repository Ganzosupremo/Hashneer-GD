class_name GatherableStats
extends Resource
## Stats that define harvesting resources from node(s)

signal remaining_changed(remaining : int, change : int)

## The highest number of gathers that this component should be able to
## hold at one time
@export_range(1, 100, 1, "or_greater") var maximum = 1

## The number of gathers this component has before it is considered depleted
@export var remaining = 1 :
	set(value):
		if value == remaining:
			return
			
		var last_value = remaining
		
		# Cannot have more remaining than the maximum
		remaining = min(value, maximum)
		var change = remaining - last_value
		remaining_changed.emit(remaining, change)

## The base gather time for a Gatherable node to be harvested once
@export_range(0.0, 100.0, .1, "or_greater") var gather_time : float = 1.0
