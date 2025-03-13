## Defines a source of gathering resources from other nodes in the game
class_name Gatherer
extends Resource


## Speed at which the gatherer gathers from gatherable targets
@export var gather_rate : float = 1.0

## To get final drop rate, take the multiplier times the base drop rate
@export var drop_rate_multiplier = 1.0

## Sound on gather
@export var sound_gather : AudioStream

## What types are allowed by this node to harvest?
## If left empty, all types will be accepted instead
@export var accepted_types : Array[GatherType] = []
