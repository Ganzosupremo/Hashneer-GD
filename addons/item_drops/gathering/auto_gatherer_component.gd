class_name AutoGathererComponent
extends Gatherer
## Automatically calls gather on the Gatherable node periodically

signal auto_gathered(gatherer)

## Node considered to be gathering the resources, this must be a Gatherable
@export var gatherables : Array

## In real world seconds
@export var frequency : float = 10.0

## Number to gather per frequency period
@export var amount = 1

var time_since_gather = 0.0

func _process(delta):
	time_since_gather += delta
	
	if time_since_gather >= frequency:
		auto_gather()
		time_since_gather = 0

func auto_gather():
	for gatherable in gatherables:
		var event = GatherEvent.new(gatherable, self, amount)
		gatherable.gather(event)
