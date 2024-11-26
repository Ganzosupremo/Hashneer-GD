extends Node2D

@onready var ai_timer: Timer = %AITimer
@onready var time_left_ui = %TimeLeftUI

@export var time: float = 0.0

var block: BitcoinBlock = null

func _ready() -> void:
	BitcoinNetwork.block_found.connect(stop_mining)
	ai_timer.timeout.connect(on_timeout)
	ai_timer.start(time)
	GameManager.player.get_health_node().zero_health.connect(on_zero_power)

func on_zero_power() -> void:
	stop_mining()

func _process(_delta: float) -> void:
	time_left_ui.update_label(str(roundf(ai_timer.time_left)))

func on_timeout() -> void:
	BitcoinNetwork.mine_block("AI")

func stop_mining() -> void:
	ai_timer.stop()

func _on_quadrant_builder_map_builded() -> void:
	pass
