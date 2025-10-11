## This script handles the health and regeneration of 
## any entity that is a fracture body.
class_name FractureBodyHealthComponent extends HealthComponent

@export_category("Regeneration")
@export var advanced_regeneration: bool = false
@export var regeneration_interval_range: Vector2 = Vector2.ZERO
@export_range(0.0, 1.0, 0.1) var regeneration_start_threshold : float = 0.5
@export var regeneration_amount: float = 10.0
@export var regeneration_color: Color = Color.WHITE
## if health percent is above that threshold the start polygon is used instead of morphing polygons.
@export_range(0.0, 1.0, 0.1) var heal_treshold : float = 0.8

var total_frame_heal_amount : float = 0.0
var regeneration_timer : Timer = null
var regeneration_started : bool = false

func create_regeneration_timer() -> Timer:
	if regeneration_timer == null:
		regeneration_timer = Timer.new()
		regeneration_timer.autostart = false
		regeneration_timer.one_shot = true
		add_child(regeneration_timer)
		return regeneration_timer
	else:
		return regeneration_timer

func regenerate(ref: BaseEnemy) -> void:
	var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var rand_time : float = _rng.randf_range(abs(regeneration_interval_range.x), abs(regeneration_interval_range.y))
	start_regeneration_timer(rand_time)
	if not regeneration_started:
		change_regeneration_state(true)
		ref.applyColor(regeneration_color)

func change_regeneration_state(state: bool) -> void:
	regeneration_started = state

func start_regeneration_timer(wait_time: float) -> void:
	regeneration_timer.start(wait_time)

func stop_regeneration_timer() -> void:
	regeneration_timer.stop()
	regeneration_started = false

func is_regenerating() -> bool:
	return regeneration_started

func can_regenerate() -> bool:
	return (get_health_percentage() < regeneration_start_threshold or regeneration_started) and regeneration_timer.is_stopped()

func can_be_healed() -> bool:
	return get_health_percentage() < 1.0 and not is_dead()

func has_regeneration() -> bool:
	return regeneration_timer != null and regeneration_amount > 0.0

func has_advanced_regeneration() -> bool:
	return advanced_regeneration

func is_dead() -> bool:
	return current_health <= 0.0
