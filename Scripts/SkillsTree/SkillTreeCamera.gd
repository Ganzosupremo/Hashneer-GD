extends Camera2D

@export var ZOOM_SPEED: float = 0.2
@export var MIN_ZOOM: float = 0.5
@export var MAX_ZOOM: float = 5.0
@export var BASE_MOVE_SPEED: float = 2.0
@export var SMOOTH_FACTOR: float = 0.1

var dragging: bool = false
var last_clicked_position: Vector2 = Vector2.ZERO
var target_zoom: float = 1.0
var target_position: Vector2 = Vector2.ZERO

func _ready():
	target_position = position

func _process(_delta):
	# Smoothly interpolate the zoom
	var current_zoom = zoom.x
	current_zoom = lerp(current_zoom, target_zoom, SMOOTH_FACTOR)
	zoom = Vector2(current_zoom, current_zoom)

	# Smoothly interpolate the position
	position = position.lerp(target_position, SMOOTH_FACTOR)

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("skill_tree_zoom_in"):
		target_zoom = max(MIN_ZOOM, target_zoom - ZOOM_SPEED)
	elif Input.is_action_pressed("skill_tree_zoom_out"):
		target_zoom = min(MAX_ZOOM, target_zoom + ZOOM_SPEED)
	
	if Input.is_action_pressed("skill_tree_drag") && !event is InputEventKey:
		if !dragging:
			last_clicked_position = event.position
		dragging = true

		var delta: Vector2 = event.position - last_clicked_position
		last_clicked_position = event.position
		var move_speed_adjusted = BASE_MOVE_SPEED / zoom.x
		target_position -= move_speed_adjusted * delta
	elif Input.is_action_just_released("skill_tree_drag") && !event is InputEventKey:
		dragging = false


