class_name ChargingEnemy extends BaseEnemy

@export var charge_cooldown_range: Vector2 = Vector2(2.0, 4.0)
@export var charge_windup_time: float = 0.3
@export var charge_duration: float = 0.5
@export var charge_speed: float = 600.0
@export var charge_damage_range: Vector2 = Vector2(10.0, 20.0)
@export var charge_color: Color = Color(1.0, 0.3, 0.3)
## Between charges it stalks the player at this distance instead of walking into them.
@export var stalk_distance: float = 320.0
## Seconds of player movement the charge leads its aim by.
@export var aim_lead_time: float = 0.35
@export var telegraph_color: Color = Color(1.0, 0.3, 0.3, 0.45)

@onready var _damage_area_polygon: CollisionPolygon2D = $DamageArea/DamageAreaPolygon

enum ChargeState { IDLE, WINDING_UP, CHARGING, COOLDOWN }

var _charge_state: ChargeState = ChargeState.COOLDOWN
var _charge_timer: Timer
var _charge_direction: Vector2 = Vector2.ZERO
var _charge_hit_bodies: Array[Node] = []
var _original_color: Color
var _telegraph: Line2D
var _stalk_clockwise: bool = true

func _ready() -> void:
	super._ready()
	_original_color = color_default
	_charge_timer = Timer.new()
	add_child(_charge_timer)
	_charge_timer.timeout.connect(_on_charge_timer_timeout)
	_stalk_clockwise = _rng.randf() > 0.5
	_telegraph = Line2D.new()
	_telegraph.top_level = true
	_telegraph.width = 6.0
	_telegraph.default_color = telegraph_color
	_telegraph.visible = false
	add_child(_telegraph)
	_schedule_next_charge()

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	return orbit_direction(threat.global_position, stalk_distance, _stalk_clockwise)

func _physics_process(delta: float) -> void:
	if isKnockbackActive(): 
		return
	
	if _charge_state == ChargeState.CHARGING and !is_player_dead:
		_handle_screen_wrapping()
		linear_velocity = _charge_direction * charge_speed
		if rotate_towards_velocity:
			global_rotation = _charge_direction.angle()
	elif _charge_state == ChargeState.WINDING_UP:
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, delta * 10.0)
	else:
		super._physics_process(delta)

func _on_body_entered(body: Node2D) -> void:
	if _charge_state == ChargeState.CHARGING and body is PlayerController:
		if not _charge_hit_bodies.has(body):
			_charge_hit_bodies.append(body)
			var args: LevelBuilderArgs = GameManager.get_level_args()
			var dmg = randf_range(charge_damage_range.x, charge_damage_range.y)
			var multiplier = args.enemy_damage_multiplier if args else 1.0
			body.damage(dmg * multiplier, global_position)

func _on_charge_timer_timeout() -> void:
	match _charge_state:
		ChargeState.WINDING_UP:
			_start_charge()
		ChargeState.CHARGING:
			_end_charge()
		ChargeState.COOLDOWN:
			_windup_charge()

func _windup_charge() -> void:
	if is_player_dead:
		_schedule_next_charge()
		return
	
	var player: PlayerController = GameManager.get_player()
	if player:
		# Lead the shot: aim where the player is going
		var aim_at: Vector2 = player.global_position + player.velocity * aim_lead_time
		_charge_direction = global_position.direction_to(aim_at)
	
	_charge_state = ChargeState.WINDING_UP
	applyColor(charge_color)
	_show_telegraph()
	_charge_timer.start(charge_windup_time)

func _show_telegraph() -> void:
	var length: float = charge_speed * charge_duration
	_telegraph.points = PackedVector2Array([global_position, global_position + _charge_direction * length])
	_telegraph.modulate.a = 0.0
	_telegraph.visible = true
	create_tween().tween_property(_telegraph, "modulate:a", 1.0, charge_windup_time)

func _start_charge() -> void:
	_charge_state = ChargeState.CHARGING
	_telegraph.visible = false
	_charge_hit_bodies.clear()
	applyColor(charge_color.lightened(0.3))
	_charge_timer.start(charge_duration)

func _end_charge() -> void:
	_charge_state = ChargeState.COOLDOWN
	applyColor(_original_color)
	_stalk_clockwise = !_stalk_clockwise
	_schedule_next_charge()

func _schedule_next_charge() -> void:
	_charge_state = ChargeState.COOLDOWN
	if charge_cooldown_range != Vector2.ZERO:
		_charge_timer.start(randf_range(charge_cooldown_range.x, charge_cooldown_range.y))

func get_charge_damage() -> float:
	return randf_range(charge_damage_range.x, charge_damage_range.y)


func setPolygon(new_polygon: PackedVector2Array, exclude_main_poly: bool = false):
	super.setPolygon(new_polygon, exclude_main_poly)
	_damage_area_polygon.call_deferred("set_polygon", new_polygon)

func _on_damage_area_area_entered(area: Area2D) -> void:
	if _charge_state == ChargeState.CHARGING and area.get_parent() is PlayerController:
		var args: LevelBuilderArgs = GameManager.get_level_args()
		var dmg = randf_range(charge_damage_range.x, charge_damage_range.y)
		var multiplier = args.enemy_damage_multiplier if args else 1.0
		var player: PlayerController = area.get_parent()
		player.damage(dmg * multiplier, global_position, true, 0.15, 0.4)
