extends Node2D

@onready var ai_timer: Timer = %AITimer
@onready var time_left_ui = %TimeLeftUI

@export var time: float = 0.0

var block: BitcoinBlock = null

func _ready() -> void:
#	await QuadrantBuilder.get_instance().map_builded
#	await get_tree().get_first_node_in_group("QuadrantBuilder").map_builded
	
	
	ai_timer.timeout.connect(on_timeout)
	#ai_timer.start()
	BitcoinNetwork.block_core_destroyed.connect(on_block_core_destroyed)
	GameManager.player.get_health_node().zero_health.connect(on_zero_power)

func on_zero_power() -> void:
	stop_mining()

func on_block_core_destroyed(_height: int, _miner: String, _block: BitcoinBlock) -> void:
	stop_mining()

func _process(_delta: float) -> void:
	time_left_ui.update_label(str(roundf(ai_timer.time_left)))

func on_timeout() -> void:
	if BlockCore.get_instance() == null: return
	
	if BlockCore.get_instance().take_damage(-1, true) == true:
		block = build_block()
		BlockCore.get_instance().mine_core("AI", block)

func stop_mining() -> void:
	ai_timer.stop()

func build_block() -> BitcoinBlock:
	var ins = BitcoinBlock.new(GameManager.builder_args.level_index, Time.get_datetime_string_from_system(false, true), "Block mined by the AI")
	return ins


func _on_quadrant_builder_map_builded() -> void:
	#GameManager.player.health.zero_power.connect(on_zero_power)
	#ai_timer.start()
	pass
