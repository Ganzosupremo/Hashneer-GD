class_name TeleporterEnemy extends BaseEnemy

@export var teleport_interval_range: Vector2 = Vector2(3.0, 6.0)
@export var teleport_distance_range: Vector2 = Vector2(200.0, 400.0)
@export var teleport_fade_time: float = 0.2

var _teleport_timer: Timer
var _is_teleporting: bool = false

func _ready() -> void:
	super._ready()
	_teleport_timer = Timer.new()
	add_child(_teleport_timer)
	_teleport_timer.timeout.connect(_on_teleport_timer_timeout)
	_schedule_next_teleport()

func _on_teleport_timer_timeout() -> void:
	if is_player_dead or _is_teleporting:
		return
	
	_teleport()
	_schedule_next_teleport()

func _teleport() -> void:
	_is_teleporting = true
	
	var tween = create_tween()
	tween.tween_property(_polygon, "modulate:a", 0.0, teleport_fade_time)
	tween.tween_property(_line, "modulate:a", 0.0, teleport_fade_time)
	
	await tween.finished
	
	var distance = randf_range(teleport_distance_range.x, teleport_distance_range.y)
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * distance
	global_position += offset
	
	var tween2 = create_tween()
	tween2.tween_property(_polygon, "modulate:a", 1.0, teleport_fade_time)
	tween2.tween_property(_line, "modulate:a", 1.0, teleport_fade_time)
	
	await tween2.finished
	_is_teleporting = false

func _schedule_next_teleport() -> void:
	if teleport_interval_range != Vector2.ZERO:
		_teleport_timer.start(randf_range(teleport_interval_range.x, teleport_interval_range.y))
