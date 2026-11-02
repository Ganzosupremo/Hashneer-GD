class_name DronesAbility extends BaseAbility
## Active ability: drones orbit the player for a few seconds and shoot at the mouse cursor.

@export_range(1, 6) var drone_count: int = 2
@export_range(0.5, 30.0, 0.5) var duration: float = 8.0
@export_range(0.05, 2.0, 0.05) var fire_interval: float = 0.3
@export_range(20.0, 200.0, 5.0) var orbit_radius: float = 55.0
## Orbit speed in radians per second.
@export var orbit_speed: float = 3.0
## Ammo the drones shoot. A copy is used, the resource is never changed.
@export var ammo: AmmoDetails = preload("res://Resources/Weapons/Player/Pistol_ammo.tres")
## Share of the player's damage each drone bullet deals.
@export_range(0.1, 2.0, 0.05) var damage_share: float = 0.6
@export var drone_color: Color = Color(0.4, 0.9, 1.0)

var _drones: Array[Polygon2D] = []
var _time_left: float = 0.0
var _fire_timer: float = 0.0
var _angle: float = 0.0
var _drone_ammo: AmmoDetails

func _process(delta: float) -> void:
	super._process(delta)
	if _time_left <= 0.0:
		return
	_time_left -= delta
	_angle += orbit_speed * delta
	var player: PlayerController = get_player()
	for i in _drones.size():
		var offset: Vector2 = Vector2.RIGHT.rotated(_angle + TAU * i / _drones.size()) * orbit_radius
		_drones[i].global_position = (player.global_position if player else global_position) + offset
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_fire_all()
	if _time_left <= 0.0:
		_clear_drones()

func _on_activate() -> void:
	_clear_drones()
	_drone_ammo = ammo.make_runtime_copy() if ammo else null
	for i in drone_count:
		var drone: Polygon2D = Polygon2D.new()
		drone.polygon = PackedVector2Array([Vector2(10, 0), Vector2(-7, 7), Vector2(-4, 0), Vector2(-7, -7)])
		drone.color = drone_color
		drone.top_level = true
		add_child(drone)
		_drones.append(drone)
	_time_left = duration
	_fire_timer = 0.0

func disable() -> void:
	super.disable()
	_time_left = 0.0
	_clear_drones()

## Seconds the drones still fly, 0 when there are none.
func get_time_left() -> float:
	return max(_time_left, 0.0)

func _fire_all() -> void:
	var player: PlayerController = get_player()
	if player == null or _drone_ammo == null or !player.can_move:
		return
	_drone_ammo.get_final_damage(player.get_attack_damage_multiplier() * damage_share)
	var pool: PoolFracture = get_tree().get_first_node_in_group("PBulletsPool")
	var quadrant_builder: QuadrantBuilder = get_tree().get_first_node_in_group("QuadrantBuilder")
	var target: Vector2 = player.get_global_mouse_position()
	for drone in _drones:
		var bullet: FractureBullet = pool.getInstance() if pool else null
		if bullet == null:
			return
		var direction: Vector2 = drone.global_position.direction_to(target)
		drone.rotation = direction.angle()
		bullet.spawn(drone.global_position + direction * 12.0, direction * _drone_ammo.get_ammo_speed(), _drone_ammo.get_bullet_lifetime(), quadrant_builder, _drone_ammo)
		bullet.global_rotation = direction.angle()

func _clear_drones() -> void:
	for drone in _drones:
		if is_instance_valid(drone):
			drone.queue_free()
	_drones.clear()
