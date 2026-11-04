class_name RandomEconomicEventPicker extends Node2D
## Autoload [code]EconomicEventsManager[/code]: starts random [EconomicEvent]s and tracks how long they last.
##
## Every mined block (by the player or the AI) either counts down the active event or rolls
## [member chance_per_block] to start a new one. The block that ends an event never starts another,
## so there is always at least one calm block in between, and the same event never happens twice in a row.[br]
## Systems read the effects with [method get_multiplier], so nothing is changed in other resources
## and nothing needs to be reverted when the event ends.[br]
## Events are loaded from [constant EVENTS_DIR]. Only the active event id and its blocks left are saved.

## A new event started. Not emitted when an event is restored from the save.
signal event_started(event: EconomicEvent)
## The active event ran out of blocks. Not emitted on [method clear_event].
signal event_ended(event: EconomicEvent)
## Anything changed: an event started, ended, ticked or was loaded. Use it to refresh prices.
signal event_changed()

## Folder with the event resources, subfolders are scanned too.
const EVENTS_DIR: String = "res://Resources/EconomicEvents/"
const SaveName: String = "economic_event_picker"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

const DEFAULT_CHANCE_PER_BLOCK: float = 0.3

## Chance of a new event each block while none is active.
@export_range(0.0, 1.0, 0.01) var chance_per_block: float = DEFAULT_CHANCE_PER_BLOCK

var _events: Array[EconomicEvent] = []
var _events_by_id: Dictionary = {}  # StringName -> EconomicEvent
var _current_event: EconomicEvent = null
var _remaining_blocks: int = 0
var _last_event_id: StringName = &""
var _events_seen: int = 0


func _ready() -> void:
	_load_catalog()
	BitcoinNetwork.block_found.connect(_on_block_found)
	DebugLogger.info("EconomicEventsManager: %d events loaded." % _events.size())

func _exit_tree() -> void:
	if BitcoinNetwork.block_found.is_connected(_on_block_found):
		BitcoinNetwork.block_found.disconnect(_on_block_found)

#region Catalog

func _load_catalog() -> void:
	_events.clear()
	_events_by_id.clear()
	_scan_dir(EVENTS_DIR)
	_events.sort_custom(func(a: EconomicEvent, b: EconomicEvent) -> bool: return String(a.id) < String(b.id))
	if _events.is_empty():
		DebugLogger.error("No economic events found in " + EVENTS_DIR)

func _scan_dir(path: String) -> void:
	# list_directory() also lists remapped resources in exported builds
	for entry in ResourceLoader.list_directory(path):
		if entry.ends_with("/"):
			_scan_dir(path + entry)
			continue
		if not (entry.ends_with(".tres") or entry.ends_with(".res")):
			continue
		var event: EconomicEvent = load(path + entry) as EconomicEvent
		if event == null:
			continue
		if event.id == &"":
			event.id = StringName(entry.get_basename())
		if _events_by_id.has(event.id):
			DebugLogger.warn("Duplicate economic event id '%s', only the first one is used." % event.id)
			continue
		_events_by_id[event.id] = event
		_events.append(event)

func get_all_events() -> Array[EconomicEvent]:
	return _events

func get_event(id: StringName) -> EconomicEvent:
	return _events_by_id.get(id)

#endregion

#region State

func get_current_event() -> EconomicEvent:
	return _current_event

func is_event_active() -> bool:
	return _current_event != null and _remaining_blocks > 0

## Blocks left before the active event ends, 0 when there is none.
func get_remaining_blocks() -> int:
	return _remaining_blocks if is_event_active() else 0

## The active multiplier of [param effect] (see the effect constants of [EconomicEvent]), 1.0 when calm.
func get_multiplier(effect: StringName) -> float:
	return _current_event.get_multiplier(effect) if is_event_active() else 1.0

## How many events started in this save.
func get_events_seen() -> int:
	return _events_seen

#endregion

#region Blocks

func _on_block_found(_block: BitcoinBlock) -> void:
	advance_block()

## Counts one block: ticks the active event down or rolls for a new one.
func advance_block() -> void:
	if is_event_active():
		_remaining_blocks -= 1
		if _remaining_blocks <= 0:
			_end_event()
		else:
			event_changed.emit()
		save_data()
		return

	if randf() < chance_per_block:
		var event: EconomicEvent = _pick_random_event()
		if event:
			start_event(event)
			return
	save_data()

func _pick_random_event() -> EconomicEvent:
	var candidates: Array[EconomicEvent] = []
	var total_weight: float = 0.0
	var height: int = BitcoinNetwork.get_blockheight()
	for event in _events:
		if event.weight <= 0.0 or event.min_blockheight > height:
			continue
		if event.id == _last_event_id and _events.size() > 1:
			continue
		candidates.append(event)
		total_weight += event.weight
	if candidates.is_empty():
		return null

	var roll: float = randf() * total_weight
	for event in candidates:
		roll -= event.weight
		if roll <= 0.0:
			return event
	return candidates.back()

## Starts [param event] right away, replacing the active one without notifying its end.
func start_event(event: EconomicEvent) -> void:
	if event == null:
		return
	_current_event = event
	_remaining_blocks = maxi(1, event.duration_in_blocks)
	_last_event_id = event.id
	_events_seen += 1
	DebugLogger.log_economic_event_picked(event)
	save_data()
	event_started.emit(event)
	event_changed.emit()

func _end_event() -> void:
	var ended: EconomicEvent = _current_event
	_current_event = null
	_remaining_blocks = 0
	if ended:
		DebugLogger.log_economic_event_expired(ended)
		event_ended.emit(ended)
	event_changed.emit()

## Removes the active event without notifying, e.g. when a new epoch starts.
func clear_event() -> void:
	_current_event = null
	_remaining_blocks = 0
	save_data()
	event_changed.emit()

## Called when a new epoch starts, see [method SkillTreeManager.start_new_epoch].
func reset_for_new_epoch() -> void:
	_last_event_id = &""
	clear_event()

#endregion

#region Debug (Feature Tester)

## Starts the event with [param id], or a random one if empty. Returns [code]true[/code] on success.
func force_start_event(id: StringName = &"") -> bool:
	var event: EconomicEvent = _pick_random_event() if id == &"" else get_event(id)
	if event == null:
		return false
	start_event(event)
	return true

## Ends the active event as if its last block was mined.
func force_end_event() -> void:
	if is_event_active():
		_end_event()
		save_data()

func get_debug_info() -> String:
	var info: String = "Economic events: %d, chance per block %d%%\n" % [_events.size(), roundi(chance_per_block * 100.0)]
	if is_event_active():
		info += "Active: %s (%d blocks left)\n%s" % [_current_event.name, _remaining_blocks, _current_event.get_effects_text()]
	else:
		info += "No active event"
	return info

#endregion

#region Persistence

func save_data() -> void:
	SaveSystem.set_var(SaveName, {
		"event_id": String(_current_event.id) if is_event_active() else "",
		"remaining_blocks": _remaining_blocks if is_event_active() else 0,
		"last_event_id": String(_last_event_id),
		"events_seen": _events_seen,
	})

## Restores the active event without notifying, the top bar chip shows it.
## Old saves stored the event name of the 4 original events, those are dropped.
func load_data() -> void:
	_current_event = null
	_remaining_blocks = 0
	if SaveSystem.has(SaveName):
		var data: Dictionary = SaveSystem.get_var(SaveName)
		_last_event_id = StringName(str(data.get("last_event_id", "")))
		_events_seen = int(data.get("events_seen", 0))
		var event: EconomicEvent = get_event(StringName(str(data.get("event_id", ""))))
		var remaining: int = int(data.get("remaining_blocks", 0))
		if event and remaining > 0:
			_current_event = event
			_remaining_blocks = remaining
	event_changed.emit()

#endregion
