extends Node2D

@onready var ai_timer: Timer = %AITimer
@onready var time_left_ui = %TimeLeftUI

@export var time: float = 0.0

func _ready() -> void:
	BitcoinNetwork.block_found.connect(stop_mining)
	ai_timer.timeout.connect(on_timeout)
	GameManager.player.get_health_node().zero_health.connect(_on_zero_power)
	ai_timer.start(time)

func _on_zero_power() -> void:
	stop_mining()

func _process(_delta: float) -> void:
	time_left_ui.update_label(str(roundf(ai_timer.time_left)))

func on_timeout() -> void:
	GameManager.current_quadrant_builder.fracture_all(GameManager.current_block_core, 0.0, "AI", true)

func stop_mining(_block: BitcoinBlock = null) -> void:
	ai_timer.stop()
