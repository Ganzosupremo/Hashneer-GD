class_name SkillTreeManager extends Control

@export var main_event_bus: MainEventBus
@export var music_details: MusicDetails

@onready var _level_selector_new: LevelSelectorMenu = %LevelSelectorNew

var _skill_nodes: Array = []

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		PersistenceDataManager.load_game()
		EconomicEventsManager.pick_random_event()

func _enter_tree() -> void:
	main_event_bus.economy_event_picked.connect(_on_random_economic_event_picked)
	main_event_bus.economy_event_expired.connect(_on_random_economic_event_expired)

func _ready() -> void:
	_skill_nodes.append_array(_get_skill_nodes())
	AudioManager.change_music_clip(music_details)
	
	var id: int = 0
	for node in _skill_nodes:
		node.pressed.connect(Callable(node, "_on_skill_pressed"))
		node.set_node_identifier(id)
		id += 1

	DebugLogger.info("SkillTreeManager initialized.")

func _on_random_economic_event_picked(economic_event: EconomicEvent) -> void:
	for node in _skill_nodes:
		node.apply_random_economic_event(economic_event)

func _on_random_economic_event_expired(_economic_event: EconomicEvent) -> void:
	for node in _skill_nodes:
		node.revert_economic_event_effects()

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
