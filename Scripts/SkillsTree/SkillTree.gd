class_name SkillTreeManager extends Control

@export var main_event_bus: MainEventBus
@export var music_details: MusicDetails

@onready var _level_selector_new: LevelSelectorMenu = %LevelSelectorNew

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		PersistenceDataManager.load_game()
		EconomicEventsManager.pick_random_event()

func _ready() -> void:
	AudioManager.change_music_clip(music_details)

	Tutorial.show_once.call_deferred("skill_tree")
	DebugLogger.info("SkillTreeManager initialized.")

## Starts a new epoch (prestige): resets the chain, wallet, inflation, levels, upgrades and miners,
## and keeps the HODL points earned. See [method MiningFarm.start_new_epoch].
func start_new_epoch() -> void:
	if !MiningFarm.can_start_new_epoch(): return

	# Expire the active economic event first so upgrade costs go back to their base values
	EconomicEventsManager.force_expire_event()
	var points: int = MiningFarm.start_new_epoch()

	SkillProgress.reset_all()
	BitcoinNetwork.reset_for_new_epoch()
	BitcoinWallet.reset_for_new_epoch()
	FED.reset_for_new_epoch()
	GameManager.reset_for_new_epoch()
	PlayerStatsManager.reset_for_new_epoch()

	PersistenceDataManager.save_game(true)
	NotificationManager.show_notification("Epoch %d begins! +%d HODL points" % [MiningFarm.epoch, points], 4.0)
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.SKILL_TREE)

func _on_start_game_pressed() -> void:
	PersistenceDataManager.save_game(true)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	_level_selector_new.open()

func _on_quit_game_pressed() -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
