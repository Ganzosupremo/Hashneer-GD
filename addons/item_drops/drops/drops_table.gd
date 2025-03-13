class_name DropsTable
extends Resource
## Define odd for each scene to be dropped (instanced as a 2d object)
## into the game world

## The item pickups that can be dropped
@export var possible_drops : Array[Droppable]

## Minimum number of drops that will come from the table per generation.
## Will repeat generating items until this number is met
@export var guaranteed_drops : int = 0

## Whether odds should be tallied together and then rolled for one
## possible item rather than individualling rolling for each item
## [br][br]
## Effectively this means the odds of each are in relation to each other
## and no longer a raw percentage. Ex, if one has odds 2.0 and one has odds 1.0
## Then the 2.0 is 66.7% likely, and the 1.0 is 33.3% likely to drop but
## one of them will definitely drop per each call to generate drops.
@export var combined_odds = false

func has_possible_drops() -> bool:
	for drop in possible_drops:
		if drop.odds > 0.0:
			return true
	
	## This occurs when there are no drops or no drops with any chance of dropping
	return false
