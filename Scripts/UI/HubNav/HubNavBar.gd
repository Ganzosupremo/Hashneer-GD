class_name HubNavBar extends Control
## Top navigation bar shared by the hub screens (skill tree, armory, network visualizer).
##
## Every [HubNavTab] in the Tabs row is one screen. To add a screen: add it to
## [constant SceneManagement.HUB_SCENES] and [member SceneManagement.main_scenes],
## then instance HubNavTab.tscn in the row and pick its target in the inspector.
## Q / E (or the gamepad shoulder buttons) move to the previous / next tab.

## Any visible node in this group (popups like the level selector or settings) disables
## the Q / E shortcuts, so they don't switch screens behind an open window.
const BLOCKER_GROUP: StringName = &"hub_nav_blocker"

@onready var _tabs_row: HBoxContainer = %Tabs

var _tabs: Array[HubNavTab] = []


func _ready() -> void:
	var current: int = SceneManager.get_scene_enum(owner)
	if current == -1:
		current = SceneManager.get_current_scene_enum()

	for child in _tabs_row.get_children():
		if child is HubNavTab:
			_tabs.append(child)
			child.set_active(child.target == current)
			child.tab_selected.connect(_open_tab)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed(): return

	var step: int = 0
	if event is InputEventKey:
		match event.physical_keycode:
			KEY_Q: step = -1
			KEY_E: step = 1
	elif event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER: step = -1
			JOY_BUTTON_RIGHT_SHOULDER: step = 1
	if step == 0 or _shortcuts_blocked(): return

	var active_index: int = _active_index()
	if active_index == -1: return
	get_viewport().set_input_as_handled()
	_open_tab(_tabs[wrapi(active_index + step, 0, _tabs.size())])


func _open_tab(tab: HubNavTab) -> void:
	if tab.is_active: return
	if not SceneManager.go_to_hub(tab.target): return
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	for other in _tabs:
		other.set_active(other == tab)


func _active_index() -> int:
	for i in _tabs.size():
		if _tabs[i].is_active:
			return i
	return -1


func _shortcuts_blocked() -> bool:
	if not is_visible_in_tree() or SceneManager.is_switching: return true
	for node in get_tree().get_nodes_in_group(BLOCKER_GROUP):
		if node is CanvasItem and node.is_visible_in_tree():
			return true
	return false
