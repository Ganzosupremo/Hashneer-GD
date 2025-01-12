class_name TweenableButton extends Button

@export_category("General Settings")
## Moves the origin point to the center of the node.
@export var from_center: bool = true
## Check if some animation should play when the node loads.
@export var enter_animation: bool = false
## Makes the tween run parallel to each other.
@export var parallel_animations: bool = true
## If you want to start tweening the control node using other methods than mouse_entered and mouse_exited signals.
@export var alternative_tweening_start: bool = false
## The node's properties to tween
@export var properties: Array = [
	"scale",
	"position",
	"rotation",
	"size",
	"self_modulate",
]

@export_category("Properties for Tweening")
@export_group("Hover Animation Settings")
@export_subgroup("Tweening Settings")
## How much time the animations takes.
@export var tween_time: float = 1.0
## The type of transition for the animation.
@export var tween_transition: Tween.TransitionType
@export var tween_ease: Tween.EaseType
## Time to wait before continuing with the next tween. 
@export var tween_delay: float = 0.0
@export_subgroup("Scaling")
## How much the node scales when tweened.
@export var tween_scale: Vector2 = Vector2.ONE
@export_subgroup("Position")
## The position to be tweened.
@export var tween_position: Vector2 = Vector2.ONE
@export_subgroup("Size")
## The size to tween.
@export var tween_size: Vector2 = Vector2.ONE
@export_subgroup("Rotation")
## The tween rotation.
@export_range(0.0, 360.0, 1.0) var tween_rotation: float = 1.0
@export_subgroup("Modulation")
## The modulation for tweening.
@export var tween_modulate: Color = Color.WHITE

@export_group("Enter Animation Settings")
@export_subgroup("Tweening Settings")
@export var wait_for: Control
## It will fetch the AnimationComponentUI node automatically from this parent. The wait_for var needs to be defined
@export var wait_for_is_child: bool = false
## How much time the animations takes.
@export_range(0.0, 1.0, .1) var enter_time: float = .5
## The type of transition for the animation.
@export var enter_transition: Tween.TransitionType
@export var enter_ease: Tween.EaseType
## Time to wait before continuing with the next tween. 
@export var enter_delay: float = 0.0
@export_subgroup("Scaling")
## The scale by which the node starts from.
@export var enter_scale: Vector2 = Vector2.ZERO
@export_subgroup("Position")
## The position by which the node starts from.
@export var enter_position: Vector2 = Vector2.ZERO
@export_subgroup("Size")
## The size by which the node starts from.
@export var enter_size: Vector2 = Vector2.ZERO
@export_subgroup("Rotation")
## The rotation by which the node starts from.
@export_range(0.0, 360.0, 1.0) var enter_rotation: float = 0.0
@export_subgroup("Modulation")
## The modulation by which the node starts from.
@export var enter_modulate: Color = Color.WHITE

@onready var animation_component: AnimationComponentUI = $AnimationComponent

func _ready() -> void:
	Utils.copy_properties(self, animation_component)

# ----------------- GETTERS ---------------------

"""Sets the properties on the animation component automatically.
I'm lazy to do it manually."""
func get_properties() -> Dictionary:
	return {
		"from_center": from_center,
		"enter_animation": enter_animation,
		"parallel_animations": parallel_animations,
		"alternative_tweening_start": alternative_tweening_start,
		"properties": properties,
		"tween_time": tween_time,
		"tween_transition": tween_transition,
		"tween_ease": tween_ease,
		"tween_delay": tween_delay,
		"tween_scale": tween_scale,
		"tween_position": tween_position,
		"tween_size": tween_size,
		"tween_rotation": tween_rotation,
		"tween_modulate": tween_modulate,
		"enter_time": enter_time,
		"wait_for": wait_for.animation_component if wait_for_is_child and wait_for else null,
		"enter_transition": enter_transition,
		"enter_ease": enter_ease,
		"enter_delay": enter_delay,
		"enter_scale": enter_scale,
		"enter_position": enter_position,
		"enter_size": enter_size,
		"enter_rotation": enter_rotation,
		"enter_modulate": enter_modulate
	}
