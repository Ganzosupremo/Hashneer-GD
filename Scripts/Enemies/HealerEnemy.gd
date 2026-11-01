class_name HealerEnemy extends BaseEnemy
## Medic: follows the most hurt ally around and heals everyone close by with a pulse, while
## keeping away from the player. With nobody to follow it hangs back at a safe distance.

@export var heal_radius: float = 250.0
@export var heal_interval: float = 2.0
@export var heal_amount_range: Vector2 = Vector2(10.0, 20.0)
@export var flee_distance: float = 300.0
@export var heal_color: Color = Color(0.3, 1.0, 0.3)
## Seconds between looks for the ally to follow (the scan goes over every enemy).
@export var ally_scan_interval: float = 0.75
## Distance it keeps from the player when it has nobody to follow.
@export var safe_distance: float = 450.0

var _heal_timer: Timer
var _original_color: Color
var _ally: BaseEnemy = null
var _scan_left: float = 0.0
var _pulse_left: float = 0.0
var _clockwise: bool = true
const PULSE_TIME: float = 0.35

func _ready() -> void:
	super._ready()
	_original_color = color_default
	_clockwise = _rng.randf() > 0.5
	_scan_left = _rng.randf_range(0.0, ally_scan_interval)
	_heal_timer = Timer.new()
	add_child(_heal_timer)
	_heal_timer.wait_time = heal_interval
	_heal_timer.timeout.connect(_on_heal_timer_timeout)
	_heal_timer.start()

func _process(delta: float) -> void:
	super._process(delta)
	if _pulse_left > 0.0:
		_pulse_left -= delta
		queue_redraw()

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	_scan_left -= delta
	if _scan_left <= 0.0:
		_scan_left = ally_scan_interval
		_ally = _find_ally()
	
	var away: Vector2 = Vector2.ZERO
	var to_threat: Vector2 = threat.global_position - global_position
	if to_threat.length_squared() < flee_distance * flee_distance:
		away = -to_threat.normalized()
	
	if is_instance_valid(_ally) and !_ally.isDead():
		var to_ally: Vector2 = _ally.global_position - global_position
		var follow: Vector2 = Vector2.ZERO
		# Stay inside the heal radius, but not on top of it
		if to_ally.length_squared() > (heal_radius * 0.5) * (heal_radius * 0.5):
			follow = to_ally.normalized()
		var input: Vector2 = follow + away * 1.5
		return input.normalized() if input.length_squared() > 0.01 else Vector2.ZERO
	
	if away != Vector2.ZERO:
		return away
	return orbit_direction(threat.global_position, safe_distance, _clockwise)

## The most hurt enemy around (the closest one when nobody is hurt). Healers don't follow healers.
func _find_ally() -> BaseEnemy:
	var parent: Node = get_parent()
	if parent == null:
		return null
	var best: BaseEnemy = null
	var best_score: float = INF
	for child in parent.get_children():
		if child == self or not child is BaseEnemy or child is HealerEnemy:
			continue
		var enemy: BaseEnemy = child
		if enemy.isDead():
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		# Health dominates, distance breaks ties (and keeps it from crossing the whole map)
		var score: float = enemy.getHealthPercent() * 2000.0 + dist
		if score < best_score:
			best_score = score
			best = enemy
	return best

func _on_heal_timer_timeout() -> void:
	_heal_nearby_enemies()

func _heal_nearby_enemies() -> void:
	var enemies_holder = get_tree().get_first_node_in_group("EnemiesHolder")
	if not enemies_holder:
		return
	
	var healed_any = false
	for enemy in enemies_holder.get_children():
		if enemy == self or not enemy is BaseEnemy:
			continue
		
		if global_position.distance_to(enemy.global_position) <= heal_radius:
			var heal_amount = randf_range(heal_amount_range.x, heal_amount_range.y)
			if enemy.has_method("heal"):
				enemy.heal(heal_amount)
				healed_any = true
	
	if healed_any:
		_pulse_left = PULSE_TIME
		var tween = create_tween()
		tween.tween_property(self, "modulate", heal_color, 0.2)
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _draw() -> void:
	if _pulse_left <= 0.0:
		return
	var t: float = 1.0 - _pulse_left / PULSE_TIME
	draw_arc(Vector2.ZERO, heal_radius * t, 0.0, TAU, 40, Color(heal_color, 0.6 * (1.0 - t)), 4.0)
