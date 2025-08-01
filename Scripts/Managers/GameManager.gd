extends Node2D


@onready var vfx_manager: VFXManager = $VFXManager

@export_category("Player")
## Used to easily modify/upgrade the values needed for the player like speed, health, etc.
@export var player_details: PlayerDetails
@export_category("Main Event Buses")
@export var main_progress_event_bus: PlayerProgressEventBus
@export var main_event_bus: MainEventBus

@export_category("Levels")
@export var game_levels: Array[LevelBuilderArgs]

var levels_unlocked: int = 1
var previous_levels_unlocked_index: int = 0
var _current_level: int = 0

var current_level_args: LevelBuilderArgs = null
var player: PlayerController = null
var current_block_core: BlockCore
var current_quadrant_builder: QuadrantBuilder
var player_camera: AdvanceCamera

var loaded: bool = false

const NetworkDataSaveName: String = "network_data"
const WalletDataSaveName: String = "wallet_data"
const GameManagerSaveName: String = "save_not_nigga"

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	# Set the level index for each level
	# This is used to identify the level in the game
	# and to unlock the next level when the current one is completed
	for i in range(game_levels.size()):
			game_levels[i].level_index = i

#region Public API
func complete_level(code: String = "") -> void:
	main_event_bus.level_completed.emit(MainEventBus.LevelCompletedArgs.new(code))
	if player_in_completed_level(): return
	
	levels_unlocked = clamp(levels_unlocked + 1, 1, game_levels.size())
	previous_levels_unlocked_index = levels_unlocked - 1

func emit_level_completed(code: String = "") -> void:
	main_event_bus.level_completed.emit(MainEventBus.LevelCompletedArgs.new(code))
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_COMPLETED_NEGATIVE_SOUND_T3, AudioManager.DestinationAudioBus.SFX)

func player_in_completed_level(level_index: int = _current_level) -> bool:
	return level_index < levels_unlocked - 1

func init_tween() -> Tween:
	return create_tween()

func init_timer(delay: float) -> SceneTreeTimer:
	return get_tree().create_timer(delay)

func shake_camera(amplitude: float, frequency: float, duration: float, axis_ratio: float, armonic_ratio: Array[int], phase_offset_degrees: int, samples: int, tween_trans: Tween.TransitionType) -> void:
	player_camera.shake(amplitude, frequency, duration, axis_ratio, armonic_ratio, phase_offset_degrees, samples, tween_trans)

func shake_camera_with_magnitude(magnitude: Constants.ShakeMagnitude) -> void:
	player_camera.shake_with_preset(magnitude)

#endregion

#region Level Management
func _set_level_index(index: int) -> void:
	print("Setting Level Index: {0}".format([index]))
	_current_level = index

func get_level_index() -> int:
	return _current_level

func select_builder_args(index: int) -> void:
	current_level_args = game_levels[index]
	print("Selecting Builder Args: {0}. At index: {1}".format([current_level_args.debug_name, index]))

func get_level_args() -> LevelBuilderArgs:
	return current_level_args

func get_current_level() -> int:
	return get_level_args().level_index

#endregion

#region Persistence Data System
func save_data() -> void:
	SaveSystem.set_var(GameManagerSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	# var unlocked_weapons_keys: Array = unlocked_weapons.keys()
	return {
		"levels_unlocked": levels_unlocked,
		"previous_levels_unlocked_index": previous_levels_unlocked_index,
	}

func load_data() -> void:
	if loaded: return
	
	if !SaveSystem.has(GameManagerSaveName): return
	var data: Dictionary = SaveSystem.get_var(GameManagerSaveName)

	levels_unlocked = data["levels_unlocked"]
	previous_levels_unlocked_index = data["previous_levels_unlocked_index"]
	loaded = true

#endregion
