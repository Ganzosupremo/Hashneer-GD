class_name AnimationComponentUI extends Node

## Used to signal that the enter animation has finished.
signal entered

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


@export_category("Properties on Tweening")
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
@export var tween_rotation: float = 1.0
@export_subgroup("Modulation")
## The modulation for tweening.
@export var tween_modulate: Color = Color.WHITE

@export_group("Enter Animation Settings")
@export_subgroup("Tweening Settings")
## This node will wait to animate until the wait_for node has finished animated.
@export var wait_for: AnimationComponentUI
## How much time the animations takes.
@export var enter_time: float = 1.0
## The type of transition for the animation.
@export var enter_transition: Tween.TransitionType
@export var enter_ease: Tween.EaseType
## Time to wait before continuing with the next tween. 
@export var enter_delay: float = 0.0
@export_subgroup("Scaling")
## The scale by which the node starts from.
@export var enter_scale: Vector2 = Vector2.ONE
@export_subgroup("Position")
## The position by which the node starts from.
@export var enter_position: Vector2 = Vector2.ONE
@export_subgroup("Size")
## The size by which the node starts from.
@export var enter_size: Vector2 = Vector2.ONE
@export_subgroup("Rotation")
## The rotation by which the node starts from.
@export var enter_rotation: float = 1.0
@export_subgroup("Modulation")
## The modulation by which the node starts from.
@export var enter_modulate: Color = Color.WHITE


var target: Control
var default_scale: Vector2
var default_values: Dictionary
var tween_values: Dictionary
var enter_animation_values: Dictionary

const IMMEDIATE_TRANSITION = Tween.TRANS_LINEAR

func _ready() -> void:
	target = get_parent()
	call_deferred("_setup")

## Alternative method for starting a tween, uses the values for the hover animation
func start_tween() -> void:
	add_tween(tween_values, parallel_animations, tween_time, tween_delay, tween_transition, tween_ease)

func add_tween(values: Dictionary, parallel: bool, seconds: float, delay: float = 0.0, transition: Tween.TransitionType = Tween.TRANS_SINE, easing: Tween.EaseType = Tween.EASE_IN_OUT, entering_animation: bool = false) -> void:
	if not target: return

	var tween: Tween = GameManager.init_tween()
	tween.set_parallel(parallel)
	tween.pause()
	
	for property in properties:
		if property is not String:
			print_debug("{0}, is not a string.".format([property]))
			continue
		tween.tween_property(target, property, values[property], seconds).set_trans(transition).set_ease(easing)
	await GameManager.init_timer(delay).timeout
	tween.play()
	
	if entering_animation:
		await tween.finished
		entered.emit()

## Resets the control node to it's original state
func reset() -> void:
	add_tween(default_values, parallel_animations, 0.0)

func _setup() -> void:
	if from_center:
		target.pivot_offset = target.size / 2.0
	default_scale = target.scale
	
	default_values = {
		"scale": target.scale,
		"position": target.position,
		"rotation": target.rotation,
		"size": target.size,
		"self_modulate": target.self_modulate,
	}
	
	tween_values = {
		"scale": tween_scale,
		"position": target.position + tween_position,
		"rotation": target.rotation + deg_to_rad(tween_rotation),
		"size": target.size + tween_size,
		"self_modulate": tween_modulate,
	}
	
	enter_animation_values = {
		"scale": enter_scale,
		"position": target.position + enter_position,
		"rotation": target.rotation + deg_to_rad(enter_rotation),
		"size": target.size + enter_size,
		"self_modulate": enter_modulate,
	}
	
	_connect_signals()
	
	if enter_animation:
		call_deferred("_on_enter")
	else:
		entered.emit()

func _on_enter() -> void:
	add_tween(enter_animation_values, true, 0.0, 0.0, IMMEDIATE_TRANSITION, enter_ease, false)
	
	if !wait_for:
		add_tween(default_values, parallel_animations, enter_time, enter_delay, enter_transition, enter_ease, true)

func _connect_signals() -> void:
	if target is not Button: return
	
	target.mouse_entered.connect(add_tween.bind(
		tween_values,
		parallel_animations,
		tween_time,
		tween_delay,
		tween_transition,
		tween_ease,
		)
	)

	target.mouse_exited.connect(add_tween.bind(
		default_values,
		parallel_animations,
		tween_time,
		tween_delay,
		tween_transition,
		tween_ease,
		)
	)
	
	if !wait_for: return
	
	wait_for.entered.connect(add_tween.bind(
		default_values,
		parallel_animations,
		enter_time,
		enter_delay,
		enter_transition,
		enter_ease,
		true,
			)
		)


"""If the wait_for node is not an animation component node.
This will check if the animation component is present as a child of the node."""
#func _has_animation_component() -> bool:
	#if wait_for is AnimationComponentUI:
		#return true
	#elif wait_for is not AnimationComponentUI and wait_for.get_child(0) is AnimationComponentUI:
		#return true
	#else:
		#return false

# --------------- SHAKE ANIMATION PROPERTIES AND METHODS -----------------------------

var x_max: float = 1.5
var rotation_max: float = 10
const STOP_THRESHOLD: float = 0.1
const RECOVERY_FACTOR: float = 2.0/3

signal tween_completed

func shake_tween():
	var x = x_max
	var r = rotation_max

	while x > STOP_THRESHOLD:
		# Tilt left
		await _tilt(-x, r)
		# Tilt right
		await _tilt(x, r)
		x *= RECOVERY_FACTOR
		r *= RECOVERY_FACTOR

	# Return to center
	await _recenter()

	tween_completed.emit()


func _recenter() -> Tween:
	var tween = _create_tween()

	# Position
	tween.tween_property(target, "position:x", target.position.x, tween_time).set_trans(tween_transition).set_ease(Tween.EASE_IN)

	# Rotation
	tween.tween_property(
		target, "rotation_degrees", 0, tween_time).set_trans(tween_transition).set_ease(Tween.EASE_IN)

	return tween


func _tilt(x: float, rotation: float) -> Tween:
	var tween = _create_tween()

	# Position (horizontal shake)
	tween.tween_property(target, "position:x", target.position.x + x, tween_time).set_trans(tween_transition).set_ease(Tween.EASE_OUT)

	# Rotation (tilt)
	var adjusted_rotation = -rotation if !from_center else rotation
	tween.tween_property(target, "rotation_degrees", adjusted_rotation, tween_time).set_trans(tween_transition).set_ease(Tween.EASE_OUT)

	return tween

func _create_tween() -> Tween:
	return GameManager.init_tween()

# --------- SETTERS ------------

func set_properties(properties: Dictionary) -> void:
	for key in properties.keys():
			set(key, properties[key])
