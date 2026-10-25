class_name AIMiner extends Node2D
## AIMiner is a simple AI that mines blocks in the game.
## 
## It is used to demonstrate the mining functionality and can be replaced with a more complex AI later.[br]
## It is not intended to be a fully functional AI, but rather a placeholder for future development.


@onready var ai_timer: Timer = %AITimer
@onready var time_left_ui = %TimeLeftUI
@onready var block_core: BlockCore = %BlockCore

@export var time: float = 0.0

func _ready() -> void:
	ai_timer.timeout.connect(on_timeout)
	GameManager.get_player().get_health_node().zero_health.connect(_on_zero_power)
	GameManager._current_block_core.onBlockDestroyed.connect(stop_mining)
	GameManager.main_event_bus.level_completed.connect(stop_mining)
	# The player's hashrate makes it harder for the AI to find the block first
	ai_timer.start(time * MiningFarm.get_ai_timer_multiplier())

func stop_mining(_args: MainEventBus.LevelCompletedArgs = null) -> void:
	ai_timer.stop()

func _on_zero_power() -> void:
	stop_mining()

func _process(_delta: float) -> void:
	time_left_ui.update_label(str(roundf(ai_timer.time_left)))

func on_timeout() -> void:
	if !BitcoinNetwork.is_level_mined(GameManager.get_level_index()):
		BitcoinNetwork.mine_block("AI")
	block_core.fracture(250 , 50.0, float("inf"),Color.WHITE, true, "AI")
	GameManager.complete_level(Constants.ERROR_401)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_COMPLETED_NEGATIVE_SOUND_T2, AudioManager.DestinationAudioBus.SFX)
