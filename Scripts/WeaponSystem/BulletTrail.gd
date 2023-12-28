extends Line2D
class_name BulletTrail

## The number of points that get stored, if the trail points exceed this number, the trail end will be deleted
@export var max_length: int = 10
var queue: Array = []

func _process(_delta: float) -> void:
	var pos: Vector2 = _get_position()
	queue.push_front(pos)
	
	if queue.size() > max_length:
		queue.pop_back()
	
	clear_points()
	
	for point in queue:
		add_point(point)

func enable_trail():
	show()

func disable_trail():
	hide()

func set_trail(enabled: bool, length: int, new_gradient: Gradient):
	if enabled: 
		enable_trail()
		self.max_length = length
		self.gradient = new_gradient
	else: disable_trail()


func _get_position() -> Vector2:
	return get_parent().position
