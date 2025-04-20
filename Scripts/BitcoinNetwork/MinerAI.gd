class_name AIMiner extends Node2D

@onready var ai_timer: Timer = %AITimer
@onready var time_left_ui = %TimeLeftUI
@onready var block_core: BlockCore = %BlockCore

@export var time: float = 0.0

func _ready() -> void:
	ai_timer.timeout.connect(on_timeout)
	GameManager.player.get_health_node().zero_health.connect(_on_zero_power)
	GameManager.current_block_core.onBlockDestroyed.connect(stop_mining)
	GameManager.main_event_bus.level_completed.connect(stop_mining)
	ai_timer.start(time)

func stop_mining() -> void:
	ai_timer.stop()

func _on_zero_power() -> void:
	stop_mining()

func _process(_delta: float) -> void:
	time_left_ui.update_label(str(roundf(ai_timer.time_left)))

func on_timeout() -> void:
	GameManager.complete_level()
	block_core.fracture(250 , 50.0, float("inf"),Color.WHITE, true, "AI")
