class_name SquareEnemy extends BaseEnemy
## Basic enemy used by the Square and Triangle scenes. [member behavior] picks how it moves.

enum Behavior {
	## Follows the player (the old default for every enemy).
	CHASE,
	## Slides only horizontally or vertically, like a block, with a short stop between slides.
	BLOCK_SLIDE,
	## Circles the player and every few seconds dives straight through them.
	FLANKER,
}

@export var behavior: Behavior = Behavior.CHASE

@export_group("Block Slide", "slide_")
## Seconds each slide lasts before the block stops and picks its axis again.
@export var slide_duration_range: Vector2 = Vector2(0.6, 1.1)
@export var slide_pause_time: float = 0.25
@export var slide_speed_scale: float = 1.6

@export_group("Flanker", "flank_")
@export var flank_orbit_radius_range: Vector2 = Vector2(180.0, 260.0)
@export var flank_orbit_speed_scale: float = 1.2
## Seconds circling between two dives.
@export var flank_dive_interval_range: Vector2 = Vector2(2.5, 4.0)
@export var flank_dive_duration: float = 0.7
@export var flank_dive_speed_scale: float = 2.6
@export var flank_dive_color: Color = Color(1.0, 0.45, 0.45)

var _timer: float = 0.0
var _sliding: bool = false
var _slide_dir: Vector2 = Vector2.ZERO
var _diving: bool = false
var _dive_dir: Vector2 = Vector2.ZERO
var _clockwise: bool = true
var _orbit_radius: float = 200.0

func _ready() -> void:
	super._ready()
	_clockwise = _rng.randf() > 0.5
	_orbit_radius = _rng.randf_range(flank_orbit_radius_range.x, flank_orbit_radius_range.y)
	_timer = _rng.randf_range(0.0, 1.0) if behavior == Behavior.BLOCK_SLIDE else _rng.randf_range(flank_dive_interval_range.x, flank_dive_interval_range.y)

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null or behavior == Behavior.CHASE:
		return super._get_movement_input(delta)
	_timer -= delta
	match behavior:
		Behavior.BLOCK_SLIDE:
			return _block_slide(threat)
		Behavior.FLANKER:
			return _flank(threat)
	return Vector2.ZERO

func _block_slide(threat: Node2D) -> Vector2:
	if _timer <= 0.0:
		_sliding = !_sliding
		if _sliding:
			var to_threat: Vector2 = threat.global_position - global_position
			_slide_dir = Vector2(signf(to_threat.x), 0.0) if absf(to_threat.x) >= absf(to_threat.y) else Vector2(0.0, signf(to_threat.y))
			_timer = _rng.randf_range(slide_duration_range.x, slide_duration_range.y)
		else:
			_timer = slide_pause_time
	if !_sliding or _slide_dir == Vector2.ZERO:
		return Vector2.ZERO
	# Drop the sideways drift so it moves in clean straight lines
	linear_velocity = linear_velocity.project(_slide_dir)
	move_speed_scale = slide_speed_scale
	return _slide_dir

func _flank(threat: Node2D) -> Vector2:
	if _timer <= 0.0:
		_diving = !_diving
		if _diving:
			# Aim a bit past the player so it flies through them
			_dive_dir = global_position.direction_to(threat.global_position)
			_timer = flank_dive_duration
			linear_velocity = _dive_dir * max_speed * flank_dive_speed_scale
			applyColor(flank_dive_color)
		else:
			_clockwise = !_clockwise
			_timer = _rng.randf_range(flank_dive_interval_range.x, flank_dive_interval_range.y)
			applyColor(color_default)
	if _diving:
		move_speed_scale = flank_dive_speed_scale
		return _dive_dir
	move_speed_scale = flank_orbit_speed_scale
	return orbit_direction(threat.global_position, _orbit_radius, _clockwise)
