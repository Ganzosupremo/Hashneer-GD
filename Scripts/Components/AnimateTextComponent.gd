class_name AnimateTextComponent extends Node2D

signal animation_finished()

## Time between each character in seconds.
@export_range(0.05, 1, 0.05) var typing_speed: float = 0.05 
## Optional callback to trigger when animation finishes.
@export var on_complete_callback: Callable 

var label_node: Label # The Label node to animate text on
var _is_animating: bool = false # To track if animation is in progress

func _ready() -> void:
	label_node = get_parent()
	
	if label_node == null:
		print_debug("No Label node assigned. Please assign a Label node to `label_node`.")


## Starts the text animation. Animate the text on the label with a typing effect.[br]
## [param speed]: Time in seconds between displaying each character.[br]
## This method will set the text of the label and start the animation to reveal it character by character.
func animate_text(speed: float = 0.05) -> void:
	if _is_animating:
		stop_typing() # Stop current animation if one is running
	
	if label_node == null:
		print_debug("Label node is not assigned. Cannot animate text.")
		return
	
	typing_speed = speed
	_is_animating = true
	label_node.visible_ratio = 0.0 # Clear the label's text
	_start_typing_animation(speed)

func _start_typing_animation(speed: float) -> void:
	"""
	Gradually increase the visible_ratio to display the text character by character.
	"""
	var text_length = label_node.text.length()
	if text_length == 0:
		_is_animating = false
		animation_finished.emit()
		if on_complete_callback.is_valid():
			on_complete_callback.call()
		return
	
	# Calculate increment per character
	var increment_per_char = 1.0 / text_length
	
	while label_node.visible_ratio < 1.0 and _is_animating:
		label_node.visible_ratio += increment_per_char
		# Clamp to prevent overshooting
		label_node.visible_ratio = min(label_node.visible_ratio, 1.0)
		
		# Wait for the specified time between characters
		await GameManager.init_timer(speed).timeout
	
	label_node.visible_ratio = 1.0
	_is_animating = false
	
	animation_finished.emit()
	# Trigger callback if it's valid
	if on_complete_callback.is_valid():
		on_complete_callback.call()

func stop_typing() -> void:
	"""
	Stops the typing animation immediately.
	"""
	_is_animating = false
	label_node.visible_ratio = 1.0 # Complete the text immediately
