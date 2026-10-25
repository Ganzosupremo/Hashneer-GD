class_name ShieldedBankerEnemy extends BaseEnemy
## Enemy that walks towards the player behind a frontal guard.
## Hits that land inside the guard arc deal only a fraction of their damage,
## so the player has to flank it, use explosions or bounce bullets.

## Fraction of the damage blocked by the guard.
@export_range(0.0, 1.0, 0.05) var guard_damage_reduction: float = 0.85
## Half of the guard arc, in degrees.
@export_range(10.0, 180.0, 5.0) var guard_half_angle_deg: float = 65.0
@export var guard_color: Color = Color(1.0, 0.8, 0.2)
@export var guard_width: float = 8.0

var _guard_line: Line2D
var _guard_cos: float = 0.0

func _ready() -> void:
	super._ready()
	_guard_cos = cos(deg_to_rad(guard_half_angle_deg))
	var player: Node2D = GameManager.get_player()
	if player:
		setTarget(player)
	_create_guard_line()

func _process(delta: float) -> void:
	super._process(delta)
	if _guard_line and !isDead():
		_guard_line.global_rotation = _get_facing().angle()

func damage(damage_to_apply: Vector2, point: Vector2, knockback_force: Vector2, knockback_time: float, damage_color: Color) -> Dictionary:
	if _is_guarded(point):
		_flash_guard()
		damage_to_apply *= (1.0 - guard_damage_reduction)
		knockback_force *= (1.0 - guard_damage_reduction)
	return super.damage(damage_to_apply, point, knockback_force, knockback_time, damage_color)

func _is_guarded(point: Vector2) -> bool:
	var to_hit: Vector2 = point - global_position
	if to_hit == Vector2.ZERO:
		return false
	return to_hit.normalized().dot(_get_facing()) >= _guard_cos

func _get_facing() -> Vector2:
	var player: Node2D = GameManager.get_player()
	if player == null or is_player_dead:
		return Vector2.RIGHT.rotated(global_rotation)
	var dir: Vector2 = player.global_position - global_position
	return dir.normalized() if dir != Vector2.ZERO else Vector2.RIGHT

func _create_guard_line() -> void:
	_guard_line = Line2D.new()
	_guard_line.width = guard_width
	_guard_line.default_color = guard_color
	_guard_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_guard_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var radius: float = maxf(getPolygonRect().size.x, getPolygonRect().size.y) * 0.5 + 14.0
	var half: float = deg_to_rad(guard_half_angle_deg)
	var steps: int = 12
	for i in range(steps + 1):
		var a: float = lerpf(-half, half, float(i) / steps)
		_guard_line.add_point(Vector2.RIGHT.rotated(a) * radius)
	add_child(_guard_line)

func _flash_guard() -> void:
	if _guard_line == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_guard_line, "modulate", Color(2.0, 2.0, 2.0), 0.05)
	tween.tween_property(_guard_line, "modulate", Color.WHITE, 0.15)
