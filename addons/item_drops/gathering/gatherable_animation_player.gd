class_name GatherableAnimationPlayer
extends AnimationPlayer
## Simple animation player for managing playing animations in response to
## gatherable signal events

@export var gatherable : Gatherable :
	set(value):
		if gatherable != null:
			gatherable.depleted.disconnect(_on_depleted)
			gatherable.gathered.disconnect(_on_gathered)
			gatherable.gatherable_changed.disconnect(_on_gatherable_changed)
		
		gatherable = value
		
		if gatherable != null:
			gatherable.depleted.connect(_on_depleted)
			gatherable.gathered.connect(_on_gathered)
			gatherable.gatherable_changed.connect(_on_gatherable_changed)
			
## You only have to define animations for animations you mean to play on the gatherable object
@export_group("Animations", "anim_")

## The animation to play on depleted signal (if any)
@export var anim_depleted : StringName

## The animation to play when a successful gather event occurs (if any)
@export var anim_gathered : StringName 

## The animation to play while the object is ready to be gathered (if any)
@export var anim_ready : StringName

## The animation to play when the object is not able to be gathered (if any)
@export var anim_ungatherable : StringName

func _on_depleted():
	if not anim_depleted.is_empty():
		play(anim_depleted)
	
func _on_gathered(event : GatherEvent):
	if not anim_gathered.is_empty():
		play(anim_gathered)

func _on_gatherable_changed(p_gatherable : bool):
	if p_gatherable && not anim_ready.is_empty():
		play(anim_ready)
	elif not p_gatherable && not anim_ungatherable.is_empty():
		play(anim_ungatherable)
