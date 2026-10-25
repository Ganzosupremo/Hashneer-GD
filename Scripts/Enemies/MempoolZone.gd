class_name MempoolZone extends Node2D
## Area left by a [MempoolSpammerEnemy]. Slows the player down while they stand inside it.

var radius: float = 80.0
var lifetime: float = 6.0
var slow_multiplier: float = 0.5
var color: Color = Color(1.0, 0.55, 0.1, 0.25)

var _age: float = 0.0
const FADE_TIME: float = 0.5

func _ready() -> void:
	z_index = -1
	modulate.a = 0.0

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	# Fade in at the start and out at the end
	modulate.a = clampf(minf(_age, lifetime - _age) / FADE_TIME, 0.0, 1.0)

	var player: PlayerController = GameManager.get_player()
	if player and player.global_position.distance_squared_to(global_position) <= radius * radius:
		player.apply_slow(slow_multiplier, 0.15)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, minf(color.a * 3.0, 1.0)), 3.0)
