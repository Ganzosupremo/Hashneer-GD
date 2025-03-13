class_name AnimationToggleInteractable2D
extends Interactable2D
## Toggles a property on the AnimationTree on or off at the property path by reversing
## the current value. You can use this to control animations in the animation tree.

signal toggle_changed(toggle : bool)

## Whether the toggle is on or off
@export var toggle = false :
	set(value):
		if toggle == value:
			return
			
		toggle = value
		toggle_changed.emit(toggle)

## Animation player to play the animations on when this interactable is toggled
@export var animation_player : AnimationPlayer

## Name of the animation to play when the toggle is on
@export var anim_on : StringName = "open"

## Name of the animation to play when the toggle is off
@export var anim_off : StringName = "close"

func _do_action(p_interacter : Node):
	animation_player.active = true
	toggle = !toggle
			
	if toggle == true && animation_player.has_animation(anim_on):
		animation_player.play(anim_on)
	elif animation_player.has_animation(anim_off):
		animation_player.play(anim_off)
