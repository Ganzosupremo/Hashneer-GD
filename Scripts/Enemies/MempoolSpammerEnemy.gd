class_name MempoolSpammerEnemy extends BaseEnemy
## Fast erratic enemy: zips between random points around the player and leaves mempool zones
## behind, so the slowing zones end up scattered around the player instead of on top of them.

@export var zone_interval_range: Vector2 = Vector2(2.0, 3.0)
@export var zone_radius: float = 80.0
@export var zone_lifetime: float = 6.0
## Player speed multiplier while inside a zone.
@export_range(0.1, 1.0, 0.05) var zone_slow_multiplier: float = 0.5
@export var zone_color: Color = Color(1.0, 0.55, 0.1, 0.25)
@export var max_zones: int = 4
## Distance from the player of the random points it zips between.
@export var waypoint_distance_range: Vector2 = Vector2(180.0, 380.0)
@export var waypoint_interval_range: Vector2 = Vector2(0.9, 1.6)

var _zone_timer: Timer
var _zones: Array[MempoolZone] = []
var _waypoint_offset: Vector2 = Vector2.ZERO
var _waypoint_left: float = 0.0

func _ready() -> void:
	super._ready()
	_zone_timer = Timer.new()
	_zone_timer.one_shot = true
	add_child(_zone_timer)
	_zone_timer.timeout.connect(_on_zone_timer_timeout)
	_zone_timer.start(_rng.randf_range(zone_interval_range.x, zone_interval_range.y))

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	_waypoint_left -= delta
	# The point is relative to the player, so it keeps buzzing around them as they move
	var waypoint: Vector2 = threat.global_position + _waypoint_offset
	if _waypoint_left <= 0.0 or global_position.distance_squared_to(waypoint) < 900.0:
		_waypoint_left = _rng.randf_range(waypoint_interval_range.x, waypoint_interval_range.y)
		_waypoint_offset = Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(waypoint_distance_range.x, waypoint_distance_range.y)
		waypoint = threat.global_position + _waypoint_offset
	return global_position.direction_to(waypoint)

func _on_zone_timer_timeout() -> void:
	if isDead() or is_player_dead:
		return
	_zones = _zones.filter(func(z): return is_instance_valid(z))
	if _zones.size() < max_zones:
		var zone := MempoolZone.new()
		zone.radius = zone_radius
		zone.lifetime = zone_lifetime
		zone.slow_multiplier = zone_slow_multiplier
		zone.color = zone_color
		var parent: Node = get_parent() if get_parent() else get_tree().current_scene
		parent.add_child(zone)
		zone.global_position = global_position
		_zones.append(zone)
	_zone_timer.start(_rng.randf_range(zone_interval_range.x, zone_interval_range.y))
