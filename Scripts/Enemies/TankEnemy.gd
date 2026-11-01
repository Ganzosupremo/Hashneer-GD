class_name TankEnemy extends BaseEnemy
## Slow armored brute. Every few seconds it stops, charges a ground stomp (a growing ring shows
## its reach) and slams: the player inside the ring takes damage and gets slowed.

@export var armor_reduction: float = 0.5
@export var stomp_interval_range: Vector2 = Vector2(4.0, 6.0)
@export var stomp_windup_time: float = 0.9
@export var stomp_radius: float = 170.0
@export var stomp_damage_range: Vector2 = Vector2(12.0, 20.0)
@export_range(0.1, 1.0, 0.05) var stomp_slow_multiplier: float = 0.5
@export var stomp_slow_time: float = 1.2
## Only starts a stomp when the player is this close (no point stomping across the map).
@export var stomp_trigger_distance: float = 230.0
@export var stomp_color: Color = Color(1.0, 0.75, 0.3, 0.35)

var _stomp_cooldown: float = 0.0
var _windup_left: float = 0.0
var _flash_left: float = 0.0

func _ready() -> void:
	super._ready()
	_stomp_cooldown = _rng.randf_range(stomp_interval_range.x, stomp_interval_range.y)

func damage(damage_to_apply: Vector2, point: Vector2, knockback_force: Vector2, knockback_time: float, damage_color: Color) -> Dictionary:
	var reduced_damage = damage_to_apply * armor_reduction
	return super.damage(reduced_damage, point, knockback_force * armor_reduction, knockback_time, damage_color)

func _process(delta: float) -> void:
	super._process(delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		queue_redraw()

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		_windup_left = 0.0
		return super._get_movement_input(delta)
	if _windup_left > 0.0:
		_windup_left -= delta
		queue_redraw()
		if _windup_left <= 0.0:
			_stomp(threat)
		return Vector2.ZERO # Planted while winding up
	_stomp_cooldown -= delta
	if _stomp_cooldown <= 0.0 and global_position.distance_squared_to(threat.global_position) < stomp_trigger_distance * stomp_trigger_distance:
		_windup_left = stomp_windup_time
		return Vector2.ZERO
	return super._get_movement_input(delta)

func _stomp(threat: Node2D) -> void:
	_stomp_cooldown = _rng.randf_range(stomp_interval_range.x, stomp_interval_range.y)
	_flash_left = 0.15
	queue_redraw()
	if global_position.distance_squared_to(threat.global_position) <= stomp_radius * stomp_radius:
		deal_damage_to_player(stomp_damage_range, true)
		if threat is PlayerController:
			threat.apply_slow(stomp_slow_multiplier, stomp_slow_time)
	var camera: AdvanceCamera = GameManager.get_main_camera()
	if camera and camera.global_position.distance_squared_to(global_position) < 900.0 * 900.0:
		camera.shake_with_preset(Constants.ShakeMagnitude.Small)

func _draw() -> void:
	if _windup_left > 0.0:
		var t: float = 1.0 - _windup_left / maxf(stomp_windup_time, 0.001)
		draw_circle(Vector2.ZERO, stomp_radius * t, stomp_color)
		draw_arc(Vector2.ZERO, stomp_radius, 0.0, TAU, 40, Color(stomp_color, 0.8), 3.0)
	elif _flash_left > 0.0:
		draw_circle(Vector2.ZERO, stomp_radius, Color(stomp_color, 0.6))
