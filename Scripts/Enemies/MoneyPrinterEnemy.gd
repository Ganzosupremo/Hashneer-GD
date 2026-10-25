class_name MoneyPrinterEnemy extends BaseEnemy
## Slow enemy that keeps printing minions while it is alive.

@export var minion_scene: PackedScene
## Seconds between each print.
@export var print_interval_range: Vector2 = Vector2(3.5, 5.0)
@export var minions_per_print: int = 2
## Maximum minions from this printer alive at the same time.
@export var max_alive_minions: int = 6
@export var print_color: Color = Color(0.6, 1.0, 0.6)

var _print_timer: Timer
var _minions: Array[BaseEnemy] = []

func _ready() -> void:
	super._ready()
	_print_timer = Timer.new()
	_print_timer.one_shot = true
	add_child(_print_timer)
	_print_timer.timeout.connect(_on_print_timer_timeout)
	_schedule_next_print()

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
