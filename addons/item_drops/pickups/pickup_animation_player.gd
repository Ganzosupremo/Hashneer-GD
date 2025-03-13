class_name PickupAnimationPlayer
extends AnimationPlayer
## Plays an animation after the picked_up signal is emitted.
## Typically the animation handles removal of the object from the scene
## on complete

## The pickup to connect to and respond when the picked_up signal
## emits by playing the anim_pickup
@export var pickup : Pickup2D :
	set(value):
		if pickup != null:
			pickup.picked_up.disconnect(_on_picked_up)
			
		pickup = value
		
		if pickup != null:
			pickup.picked_up.connect(_on_picked_up)

## The animation to play once the pickup occurs
@export var anim_pickup : StringName

func _ready():
	if anim_pickup.is_empty():
		push_warning("No anim_pickup set on %s" % get_path())
	
	if pickup == null:
		push_warning("No pickup assigned to %s" % get_path())

func _on_picked_up(event : PickupEvent):
	play(anim_pickup)
