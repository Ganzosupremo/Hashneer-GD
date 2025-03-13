class_name Interactable2D
extends Area2D
## Object which does an action when an interacter interacts with it

signal interacted()

## Icon to show to represent an interaction when applicable
@export var icon : Texture

## Whether the object can be interacted with an indefinite number of times
@export var disable_on_interact = false

## Whether the object has been interacted with or not
var has_interacted = false

## Tries to interact with this node
func interaction(p_interacter : Interacter2D):
	_do_action(p_interacter)
	
	if disable_on_interact:
		self.disable_mode = CollisionObject2D.DISABLE_MODE_REMOVE
	
	has_interacted = true
	interacted.emit()

## Makes the interactable active again and resets has_interacted to false
func reset():
	has_interacted = false
	self.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE

func _do_action(_p_interacter : Node):
	push_warning("This method has no been implemented. Extend script Interactable2D to define what do interaction does for the object.")
