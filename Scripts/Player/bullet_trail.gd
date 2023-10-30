extends Line2D
class_name BulletTrail

@export var limited_lifetime: bool = false
@export var lifetime: Vector2 = Vector2(1.0, 2.0)
@export var wildness: float = 3.0
@export var min_spawn_distance: float = 5.0
@export var gravity: Vector2 = Vector2.UP
@export var line_gradient: Gradient = Gradient.new()

var tick_speed: float = 0.05
var tick: float = 0.0
var decay_tween: Tween
var wild_speed: float = .1
var point_age: Array = [0.0]

func _ready() -> void:
	gradient = line_gradient
	clear_points()
	if limited_lifetime:
		stop()

func stop() -> void:
	decay_tween = get_tree().create_tween().bind_node(self)
	decay_tween.tween_property(self, "modulate:a", 0.0, randf_range(lifetime.x, lifetime.y)).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT_IN)
	decay_tween.play()

func _process(delta: float) -> void:
	if tick > tick_speed:
		tick = 0
		for p in range(get_point_count()):
			point_age[p] += 5 * delta
			var rand_vector: Vector2 = Vector2(randf_range(-wild_speed, wild_speed), randf_range(-wild_speed, wild_speed))
			
			points[p] += gravity + (rand_vector * wildness * point_age[p])
	else:
		tick += delta
func my_add_point(point_pos: Vector2, at_pos: int = -1):
	if get_point_count() > 0 and  point_pos.distance_to(points[get_point_count()-1]) < min_spawn_distance: return
	
	point_age.append(0.0)
	add_point(point_pos, at_pos)
