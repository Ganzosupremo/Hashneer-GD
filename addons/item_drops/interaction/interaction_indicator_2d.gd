class_name InteractionIndicator2D
extends Sprite2D

## The interacter to show a icon when an available interaction is there to try
@export var interacter : Interacter2D :
	set(value):
		if interacter != null:
			interacter.targeted_changed.disconnect(_on_interacter_targeted_changed)
		
		interacter = value
		
		if interacter != null:
			interacter.targeted_changed.connect(_on_interacter_targeted_changed)

## Icon to show when the interactable has no icon set to represent the interaction
var default_icon : Texture

func _ready():
	default_icon = texture
	hide()

## Shows the icon for the interaction if one is available or hides this indicator
## if there is no interaction available
func show_interaction(p_interactable : Interactable2D):
	if p_interactable == null:
		texture = default_icon
		hide()
		return
	
	if p_interactable.icon != null:
		texture = p_interactable.icon
	else:
		texture = default_icon
		
	show()
	
func _on_interacter_targeted_changed(p_interactable : Interactable2D):
	show_interaction(p_interactable)
