class_name AnimationComponentUI extends Node

## Used to signal that the enter animation has finished.
signal entered
signal tween_completed

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

@export_group("Shake Animation Settings")
## If the pivot point should be below the node.
@export var pivot_below: bool = false
## Maximum amount of movement on the x-axis.
@export var x_max: float = 0.5
## Maximum amount of rotation.
@export var r_max: float = 0.5
## The time it takes to shake. Based on x position.
@export var stop_threshold: float = 0.1
## Duration of each tween
@export var shake_time: float = 0.5
## The type of transition for the shake animation.
@export var shake_transition: Tween.TransitionType
@export var shake_ease: Tween.EaseType
## Amount of energy retained after each shake.
@export var recovery_factor: float = 2.0/3.0

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
func start_tween(enter: bool = true) -> void:
	if enter:
		add_tween(enter_animation_values, parallel_animations, enter_time, enter_delay, IMMEDIATE_TRANSITION, enter_ease)
	else:
		add_tween(tween_values, parallel_animations, tween_time, tween_delay, tween_transition, tween_ease)

func add_tween(values: Dictionary, parallel: bool, seconds: float, delay: float = 0.0, transition: Tween.TransitionType = Tween.TRANS_SINE, easing: Tween.EaseType = Tween.EASE_IN_OUT, entering_animation: bool = false) -> void:
	if not target: 
		push_warning("No target. Returning")
		return

	var tween: Tween = GameManager.init_tween()
	tween.set_parallel(parallel)
	# tween.pause()
	
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

func _create_tween() -> Tween:
	return GameManager.init_tween()

func start_shake() -> void:
	add_shake(pivot_below, x_max, r_max, stop_threshold, shake_time, recovery_factor, shake_transition, shake_ease)

func add_shake(below_pivot: bool, max_x: float, max_r: float, threshold: float = 0.1, tween_duration: float = 0.5, energy_retained: float = 2.0/3.0, transition: Tween.TransitionType = Tween.TRANS_SINE, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	if not target: return

	var x = max_x
	var r = max_r

	while x > threshold:
		var tween: Tween = _tilt_left(below_pivot, x, r, tween_duration, transition, easing)
		await tween.finished
		#tween.free()
		x *= energy_retained
		r *= energy_retained

		_recenter()

		tween = _tilt_right(below_pivot, x, r, tween_duration, transition, easing)
		await tween.finished
		#tween.free()
		x *= energy_retained
		r *= energy_retained

		_recenter()
	
	tween_completed.emit()

func _tilt_left(_below_pivot: bool, x: float, r: float, duration: float = 0.5, transition: Tween.TransitionType = Tween.TRANS_SINE, _ease: Tween.EaseType = Tween.EASE_IN_OUT) -> Tween:
	var tween = _create_tween()
	tween.set_parallel(true)
	tween.tween_property(target, "position:x", -x, duration).set_trans(transition).set_ease(_ease)

	r = -r if _below_pivot else r
	tween.tween_property(target, "rotation_degrees", r, duration).set_trans(transition).set_ease(_ease)

	tween.play()
	return tween

func _tilt_right(_below_pivot: bool, x: float, r: float, duration: float = 0.5, transition: Tween.TransitionType = Tween.TRANS_SINE, _ease: Tween.EaseType = Tween.EASE_IN_OUT) -> Tween:
	var tween = _create_tween()

	tween.tween_property(target, "position:x", x, duration).set_trans(transition).set_ease(_ease)

	r = -r if _below_pivot else r
	tween.tween_property(target, "rotation_degrees", r, duration).set_trans(transition).set_ease(_ease)

	tween.play()
	return tween

func _recenter() -> Tween:
	var tween = _create_tween()

	var target_x: float = target.position.x
	tween.tween_property(target, "position:x", 0.0, shake_time).from(target_x).set_trans(shake_transition).set_ease(shake_ease)

	var target_r = target.rotation_degrees
	tween.tween_property(target, "rotation_degrees", 0.0, shake_time).from(target_r).set_trans(shake_transition).set_ease(shake_ease)

	tween.play()
	return tween

# --------- SETTERS ------------

func set_properties(base_properties: Dictionary) -> void:
	for key in base_properties.keys():
			set(key, base_properties[key])
