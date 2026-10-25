class_name MempoolSpammerEnemy extends BaseEnemy
## Fast wandering enemy that floods the map with mempool zones that slow the player down.

@export var zone_interval_range: Vector2 = Vector2(2.0, 3.0)
@export var zone_radius: float = 80.0
@export var zone_lifetime: float = 6.0
## Player speed multiplier while inside a zone.
@export_range(0.1, 1.0, 0.05) var zone_slow_multiplier: float = 0.5
@export var zone_color: Color = Color(1.0, 0.55, 0.1, 0.25)
@export var max_zones: int = 4

var _zone_timer: Timer
var _zones: Array[MempoolZone] = []

func _ready() -> void:
	super._ready()
	_zone_timer = Timer.new()
	_zone_timer.one_shot = true
	add_child(_zone_timer)
	_zone_timer.timeout.connect(_on_zone_timer_timeout)
	_zone_timer.start(_rng.randf_range(zone_interval_range.x, zone_interval_range.y))

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
