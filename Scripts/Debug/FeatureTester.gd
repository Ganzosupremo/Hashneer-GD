extends CanvasLayer
## In-game panel to test features (enemies, bosses, weapons, abilities, currency...).
##
## Only exists in debug builds (editor runs and debug exports), release exports remove it.[br]
## Press F1 ([constant TOGGLE_ACTION]) to open or close it.[br]
## The panel only lists the features of the current game mode: mining, infinite waves or the menus.[br]
## Enemies, bosses, weapons and abilities are listed from the game's own data, so new ones show up
## without touching the tester. Other features are registered in [TesterFeatureCatalog], or from any
## script with [method add_action] and [method add_toggle].

const SECTION_SCENE: PackedScene = preload("res://Scenes/Debug/TesterSection.tscn")
const BUTTON_SCENE: PackedScene = preload("res://Scenes/Debug/TesterFeatureButton.tscn")
const TOGGLE_ACTION: StringName = &"Feature_Tester"
const MODE_NAMES: Dictionary = {
	TesterFeature.MINING: "Mining",
	TesterFeature.WAVES: "Infinite Waves",
	TesterFeature.MENU: "Menus",
}

@onready var _panel: Control = %Panel
@onready var _mode_label: Label = %ModeLabel
@onready var _sections: VBoxContainer = %Sections
@onready var _search_edit: LineEdit = %SearchEdit
@onready var _quantity_spin_box: SpinBox = %QuantitySpinBox
@onready var _pause_check_box: CheckBox = %PauseCheckBox
@onready var _status_label: Label = %StatusLabel
@onready var _empty_label: Label = %EmptyLabel

var _features: Array[TesterFeature] = []
var _paused_by_tester: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_panel.hide()
	TesterFeatureCatalog.register_defaults(self)
	SceneManager.scene_switched.connect(_on_scene_switched)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		toggle()
		get_viewport().set_input_as_handled()

#region Public API

func add_action(category: String, label: String, modes: Array, action: Callable, tooltip: String = "") -> TesterFeature:
	var feature := TesterFeature.new()
	feature.category = category
	feature.label = label
	feature.modes.assign(modes)
	feature.action = action
	feature.tooltip = tooltip
	return register(feature)

## Adds an on/off feature, [param is_on] returns the state and [param set_on] receives the new one.
func add_toggle(category: String, label: String, modes: Array, is_on: Callable, set_on: Callable, tooltip: String = "") -> TesterFeature:
	var feature := add_action(category, label, modes, func() -> void: set_on.call(not is_on.call()), tooltip)
	feature.toggle_state = is_on
	return feature

func register(feature: TesterFeature) -> TesterFeature:
	_features.append(feature)
	if is_open():
		_rebuild()
	return feature

func get_features() -> Array[TesterFeature]:
	return _features

## The game mode the features are filtered by, one of the [TesterFeature] mode constants.
func get_mode() -> StringName:
	var scene: Node = get_tree().current_scene
	if scene is WavesGameMode:
		return TesterFeature.WAVES
	if scene is MiningGameMode:
		return TesterFeature.MINING
	return TesterFeature.MENU

## How many times spawn and currency features repeat.
func get_quantity() -> int:
	return int(_quantity_spin_box.value)

## Shows [param text] in the panel's status line.
func report(text: String) -> void:
	_status_label.text = text
	DebugLogger.debug("FeatureTester: " + text)

func is_open() -> bool:
	return _panel.visible

func toggle() -> void:
	if is_open():
		close()
	else:
		open()

func open() -> void:
	_rebuild()
	_panel.show()
	if _pause_check_box.button_pressed:
		_pause_game()

func close() -> void:
	_panel.hide()
	_unpause_game()
	var focused: Control = _panel.get_viewport().gui_get_focus_owner()
	if focused:
		focused.release_focus()

#endregion

func _rebuild() -> void:
	for section in _sections.get_children():
		_sections.remove_child(section)
		section.queue_free()

	var mode: StringName = get_mode()
	_mode_label.text = "Mode: %s" % MODE_NAMES.get(mode, String(mode))
	var filter: String = _search_edit.text.strip_edges().to_lower()

	var by_category: Dictionary = {}
	for feature in _features:
		if not feature.is_available_in(mode):
			continue
		if filter != "" and not (feature.label.to_lower().contains(filter) or feature.category.to_lower().contains(filter)):
			continue
		if not by_category.has(feature.category):
			by_category[feature.category] = []
		by_category[feature.category].append(feature)

	for category in by_category:
		var section: TesterSection = SECTION_SCENE.instantiate()
		_sections.add_child(section)
		section.set_title(category)
		for feature in by_category[category]:
			var button: TesterFeatureButton = BUTTON_SCENE.instantiate()
			section.add_feature_button(button)
			button.setup(feature)
			button.feature_pressed.connect(_on_feature_pressed)

	_empty_label.visible = by_category.is_empty()

func _refresh_buttons() -> void:
	for section in _sections.get_children():
		for button in section.get_feature_buttons():
			button.refresh()

func _pause_game() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	_paused_by_tester = true

func _unpause_game() -> void:
	if not _paused_by_tester:
		return
	get_tree().paused = false
	_paused_by_tester = false

#region Signals

func _on_feature_pressed(feature: TesterFeature) -> void:
	report("> " + feature.label)
	feature.action.call()
	_refresh_buttons()

func _on_scene_switched() -> void:
	if is_open():
		_rebuild()

func _on_search_edit_text_changed(_new_text: String) -> void:
	_rebuild()

func _on_pause_check_box_toggled(toggled_on: bool) -> void:
	if not is_open():
		return
	if toggled_on:
		_pause_game()
	else:
		_unpause_game()

func _on_close_button_pressed() -> void:
	close()

#endregion
