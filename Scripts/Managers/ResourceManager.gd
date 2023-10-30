extends Node2D

signal resource_added(resource_amount: int)

var resource_amount: float = 0

func add_resource(amount: float):
	resource_amount += amount
	emit_signal("resource_added", resource_amount)
	print(resource_amount)
