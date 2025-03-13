class_name AddAfterSecondsComponent
extends ItemDropsNode
## Calls the add(int) method on another node when a number of 
## real world seconds passes. 

## The target which "add(amount : int)" will be called on after the period elapses
@export var add_target : Node

## Add this to the add_target per period
@export var amount = 1

## Number of age values per increase
@export var period = 60

var seconds_since_add = 0

func _process(delta):
	seconds_since_add += delta
	
	var periods = seconds_since_add / period
	
	for i in periods:
		add_target.add(amount)
		seconds_since_add -= period
