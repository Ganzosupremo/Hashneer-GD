extends Line2D
class_name BulletTrailComponent

## The number of points that get stored, if the trail points exceed this number, the trail end will be deleted
var max_length: int = 10
var queue: Array = []


func _process(_delta: float) -> void:
	var pos: Vector2 = _get_global_position()
	queue.push_front(pos)

	if queue.size() > max_length:
		queue.pop_back()
	
	clear_points()
	
	for point in queue:
		add_point(point)

func enable_trail():
	clear()
	show()

func disable_trail():
	clear()
	hide()

func clear() -> void:
	clear_points()

func spawn(length: int, new_gradient: Gradient, new_width: float = 20.0) -> void:
	width = new_width
	max_length = length
	gradient = new_gradient
	enable_trail()


func despawn() -> void:
	queue_free()

func _get_global_position() -> Vector2:
	return get_parent().position
