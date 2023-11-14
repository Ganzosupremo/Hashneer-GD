extends Camera2D

const ZOOM_SPEED: float = 0.2
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 5.0

var dragging: bool = false
var last_clicked_position: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("skill_tree_zoom_in"):
		var zoom = self.zoom.x
		zoom = max(MIN_ZOOM, zoom - ZOOM_SPEED)
		self.zoom = Vector2(zoom,zoom)
	elif Input.is_action_pressed("skill_tree_zoom_out"):
		var zoom = self.zoom.x
		zoom = min(MAX_ZOOM, zoom + ZOOM_SPEED)
		self.zoom = Vector2(zoom,zoom)
	
	if Input.is_action_pressed("skill_tree_drag") && !event is InputEventKey:
		if !dragging:
			last_clicked_position = event.position
		dragging = true

		var delta: Vector2 = event.position - last_clicked_position
		last_clicked_position = event.position
		position = position - zoom.x*delta * 2.0
	elif Input.is_action_just_released("skill_tree_drag") && !event is InputEventKey:
		dragging = false


