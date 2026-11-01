class_name MoneyPrinterEnemy extends BaseEnemy
## Slow enemy that keeps printing minions while it is alive. It hides from the player: backs off
## when they get close, stays put to print at a safe distance and only comes back when far away.

@export var minion_scene: PackedScene
## Seconds between each print.
@export var print_interval_range: Vector2 = Vector2(3.5, 5.0)
@export var minions_per_print: int = 2
## Maximum minions from this printer alive at the same time.
@export var max_alive_minions: int = 6
@export var print_color: Color = Color(0.6, 1.0, 0.6)
## Distance band it keeps from the player: backs off below x, comes closer above y.
@export var keep_away_range: Vector2 = Vector2(380.0, 650.0)
## Speed while backing off (it panics a bit).
@export var flee_speed_scale: float = 1.4

var _print_timer: Timer
var _minions: Array[BaseEnemy] = []

func _ready() -> void:
	super._ready()
	_print_timer = Timer.new()
	_print_timer.one_shot = true
	add_child(_print_timer)
	_print_timer.timeout.connect(_on_print_timer_timeout)
	_schedule_next_print()

func _get_movement_input(delta: float) -> Vector2:
	var threat: Node2D = get_threat()
	if threat == null:
		return super._get_movement_input(delta)
	var to_threat: Vector2 = threat.global_position - global_position
	var dist_sq: float = to_threat.length_squared()
	if dist_sq < keep_away_range.x * keep_away_range.x:
		move_speed_scale = flee_speed_scale
		return -to_threat.normalized()
	if dist_sq > keep_away_range.y * keep_away_range.y:
		return to_threat.normalized()
	return Vector2.ZERO

func _schedule_next_print() -> void:
	_print_timer.start(_rng.randf_range(print_interval_range.x, print_interval_range.y))

func _on_print_timer_timeout() -> void:
	if isDead() or is_player_dead or minion_scene == null:
		return
	_minions = _minions.filter(func(m): return is_instance_valid(m) and !m.isDead())
	var to_print: int = mini(minions_per_print, max_alive_minions - _minions.size())
	for i in range(to_print):
		var minion: BaseEnemy = minion_scene.instantiate()
		var offset: Vector2 = Vector2.RIGHT.rotated(_rng.randf() * TAU) * 60.0
		spawn_extra_enemy(minion, global_position + offset)
		_minions.append(minion)
	if to_print > 0:
		var tween: Tween = create_tween()
		tween.tween_property(self, "modulate", print_color, 0.15)
		tween.tween_property(self, "modulate", Color.WHITE, 0.25)
	_schedule_next_print()
