class_name SkillTreeManager extends Control

@export var main_event_bus: MainEventBus
@export var music_details: MusicDetails

@onready var _level_selector_new: LevelSelectorMenu = %LevelSelectorNew

var _skill_nodes: Array = []

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		PersistenceDataManager.load_game()
		EconomicEventsManager.pick_random_event()

func _ready() -> void:
	_skill_nodes.append_array(_get_skill_nodes())
	AudioManager.change_music_clip(music_details)
	
	var id: int = 0
	for node in _skill_nodes:
		node.pressed.connect(Callable(node, "_on_skill_pressed"))
		node.set_node_identifier(id)
		id += 1

	_add_mining_farm_ui()
	_add_stats_screen()
	Tutorial.show_once.call_deferred("skill_tree")
	DebugLogger.info("SkillTreeManager initialized.")

func _add_mining_farm_ui() -> void:
	var farm_ui: MiningFarmUI = MiningFarmUI.new()
	$FrontLayer.add_child(farm_ui)
	farm_ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 14)
	farm_ui.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	farm_ui.position.y = 73.0
	farm_ui.new_epoch_requested.connect(start_new_epoch)

func _add_stats_screen() -> void:
	var stats_screen: StatsScreenUI = StatsScreenUI.new()
	$FrontLayer.add_child(stats_screen)
	var stats_button: Button = preload("res://Scenes/UI/CustomButtonNew.tscn").instantiate()
	stats_button.custom_minimum_size = Vector2(140, 50)
	stats_button.text = "Stats"
	$FrontLayer/ButtonContainer.add_child(stats_button)
	$FrontLayer/ButtonContainer.move_child(stats_button, 1)
	stats_button.pressed.connect(stats_screen.open)

## Starts a new epoch (prestige): resets the chain, wallet, inflation, levels, upgrades and miners,
## and keeps the HODL points earned. See [method MiningFarm.start_new_epoch].
func start_new_epoch() -> void:
	if !MiningFarm.can_start_new_epoch(): return

	# Expire the active economic event first so upgrade costs go back to their base values
	EconomicEventsManager.force_expire_event()
	var points: int = MiningFarm.start_new_epoch()

	for node in _skill_nodes:
		var key: String = node.save_name if !node.save_name.is_empty() else node.skillnode_data.upgrade_name
		SaveSystem.delete(key)
		node.skillnode_data.upgrade_level = 0
		# Keep the scene switch from saving the old node state back, nodes reload with their defaults
		node.remove_from_group("PersistentNodes")

	BitcoinNetwork.reset_for_new_epoch()
	BitcoinWallet.reset_for_new_epoch()
	FED.reset_for_new_epoch()
	GameManager.reset_for_new_epoch()
	PlayerStatsManager.reset_for_new_epoch()

	PersistenceDataManager.save_game(true)
	NotificationManager.show_notification("Epoch %d begins! +%d HODL points" % [MiningFarm.epoch, points], 4.0)
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.SKILL_TREE)

# func _on_random_economic_event_picked(economic_event: EconomicEvent) -> void:
# 	for node in _skill_nodes:
# 		node.apply_random_economic_event(economic_event)

# func _on_random_economic_event_expired(_economic_event: EconomicEvent) -> void:
# 	for node in _skill_nodes:
# 		node.revert_economic_event_effects()

func _get_skill_nodes() -> Array:
	var nodes: Array = []
	for child in %UpgradesHolder.get_children():
		if child is SkillNode:
			nodes.append(child)
	return nodes

func _on_start_game_pressed() -> void:
	PersistenceDataManager.save_game(true)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	_level_selector_new.open()

func _on_quit_game_pressed() -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
