class_name RandomEconomicEventPicker extends Node2D
## Economic Event System with Persistence Data
##
## This system manages random economic events that affect the game economy.[br]
## Key Features:[br]
## - Events have a duration measured in bitcoin blocks[br]
## - Events persist across game sessions (save/load)[br]
## - Automatically tracks block progression and decrements event duration[br]
## - Prevents overlapping events (only one active at a time)[br]
## - Automatically tries to pick new events when none are active[br]
##
## Usage:[br]
## 1. Add economic events to the [member economic_events] array in the editor[br]
## 2. Connect the [member main_event_bus] resource[br]
## 3. The system will automatically:[br]
##    - Pick random events based on [member _chance_of_event][br]
##    - Track their duration as blocks are mined[br]
##    - Save/restore events when the game is quit/loaded[br]
##    - Expire events and pick new ones automatically[br]

## Emitted when a new economic event is picked and becomes active
signal event_picked(economic_event: EconomicEvent)
## Emitted when an economic event expires (duration reaches 0)
signal event_expired(economic_event: EconomicEvent)

@export var main_event_bus: MainEventBus
@export var economic_events: Array[EconomicEvent]

var _current_event: EconomicEvent = null
var _event_duration: int = 0
var _chance_of_event: float = 0.5  # 50% chance of an event occurring each block. 50% testing value, can be adjusted later
var _economic_events_dict: Dictionary = {}

const SaveName: String = "economic_event_picker"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

## Helper function for conditional debug logging
func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print_debug("[EconomicEvents] " + message)

func _ready() -> void:
	if economic_events.is_empty():
		push_error("No economic events defined. Please add events to the economic_events array.")
		return
	
	for event in economic_events:
		if event.name in _economic_events_dict:
			push_warning("Duplicate economic event name found: " + event.name + ". Only the first occurrence will be used.")
		else:
			_economic_events_dict[event.name] = event
	
	# Connect to the bitcoin network to track new blocks
	BitcoinNetwork.block_found.connect(_on_block_found)
	# Load saved data if exists
	load_data()

func _exit_tree() -> void:
	# Disconnect from bitcoin network if connected
	if BitcoinNetwork.block_found.is_connected(_on_block_found):
		BitcoinNetwork.block_found.disconnect(_on_block_found)

## Pick a random economic event from the available events.
## This method checks the chance of an event occurring and picks a random event if conditions are met.
## If an event is already active, it will not pick a new one.
## If no events are available, it will log an error.
func pick_random_event() -> void:
	if _economic_events_dict.is_empty():
		push_error("No economic events available to pick.")
		return
	
	# Don't pick a new event if one is already active
	if is_event_active():
		_debug_log("Economic event already active. Skipping new event selection.")
		return
	
	if randi() % 100 > _chance_of_event * 100:  # Convert chance to percentage
		return

	var event_names = _economic_events_dict.keys()
	var random_index: int = randi() % event_names.size()
	var random_event_name = event_names[random_index]
	_current_event = _economic_events_dict[random_event_name]
	_event_duration = _current_event.duration_in_blocks
	event_picked.emit(_current_event)
	main_event_bus.economy_event_picked.emit(_current_event)
	_debug_log("Picked economic event: " + _current_event.name + " with impact: " + str(_current_event.impact) + " for currency: " + str(_current_event.currency_affected) + " type: " + str(_current_event.event_type))
	
	# Save the current state
	save_data()

func _on_block_found(_block: BitcoinBlock) -> void:
	# This method is called every time a new block is mined in the game
	# Since blocks are only generated during active gameplay, events only
	# progress when the player is actually playing the game
	if _current_event == null or _event_duration <= 0:
		# No active event, try to pick a new one
		pick_random_event()
		return
	
	_event_duration -= 1
	_debug_log("Economic event duration decreased. Remaining blocks: " + str(_event_duration))
	
	# Save updated duration
	save_data()
	
	if _event_duration <= 0:
		_expire_current_event()
		# After expiring, try to pick a new event
		pick_random_event()

func _expire_current_event() -> void:
	if _current_event == null:
		return
	
	event_expired.emit(_current_event)
	main_event_bus.economy_event_expired.emit(_current_event)
	_current_event = null
	_event_duration = 0
	
	# Save the cleared state
	save_data()

## Get the current active economic event.
func get_current_event() -> EconomicEvent:
	return _current_event

## Get the remaining duration of the current event in blocks.
func get_remaining_duration() -> int:
	return _event_duration

## Check if an economic event is currently active.
## Returns true if there is an active event with remaining duration.
## Returns false if no event is active or duration has expired.
func is_event_active() -> bool:
	return _current_event != null and _event_duration > 0

## @experimental: Force expire the current event. Only meant for debugging.
func force_expire_event() -> void:
	if _current_event != null:
		_expire_current_event()

## Set the chance of an event occurring each block (0.0 to 1.0).
func set_chance_of_event(new_chance: float) -> void:
	_chance_of_event = clamp(new_chance, 0.0, 1.0)

## Get the current chance of an event occurring each block.
func get_chance_of_event() -> float:
	return _chance_of_event

## @experimental: Force pick a specific event by name, or random if name is empty. Returns [code]true[/code] if successful. Only meant for debugging.
func force_pick_event(event_name: String = "") -> bool:
	if _economic_events_dict.is_empty():
		push_error("No economic events available to pick.")
		return false
	
	# Don't pick a new event if one is already active
	if is_event_active():
		_debug_log("Economic event already active. Use force_expire_event() first.")
		return false
	
	if event_name.is_empty():
		# Pick random event
		var event_names = _economic_events_dict.keys()
		var random_index: int = randi() % event_names.size()
		event_name = event_names[random_index]
	
	if event_name not in _economic_events_dict:
		push_error("Economic event '" + event_name + "' not found.")
		return false
	
	_current_event = _economic_events_dict[event_name]
	_event_duration = _current_event.duration_in_blocks
	event_picked.emit(_current_event)
	main_event_bus.economy_event_picked.emit(_current_event)
	_debug_log("Force picked economic event: " + _current_event.name)
	
	# Save the current state
	save_data()
	return true

## Gets list of all available economic events names
func get_available_events() -> Array:
	return _economic_events_dict.keys()

## Get debug information about the current state of the economic event picker.
## This includes active events, their durations, and chance settings.
func get_debug_info() -> String:
	var info: String = "=== Economic Event Picker Debug Info ===\n"
	info += "Available events: " + str(get_available_events().size()) + "\n"
	info += "Chance per block: " + str(_chance_of_event * 100) + "%\n"
	if is_event_active():
		info += "Current event: " + _current_event.name + "\n"
		info += "Remaining duration: " + str(_event_duration) + " blocks\n"
		info += "Event type: " + str(_current_event.event_type) + "\n"
		info += "Impact: " + str(_current_event.impact) + "\n"
		info += "Currency affected: " + str(_current_event.currency_affected) + "\n"
	else:
		info += "No active event\n"
	return info

## @experimental: Revert all economic event effects on all skill nodes. ONLY meant for debugging.
func force_revert_all_effects() -> void:
	_debug_log("Force reverting all economic event effects")
	main_event_bus.economy_event_expired.emit(_current_event)

#region Persistence Data System

## Save the current state of the economic event picker to persistent storage.
## This includes the current event name and remaining duration.
## This allows the event state to be restored when the game is loaded.
func save_data() -> void:
	SaveSystem.set_var(SaveName, _build_save_dictionary())

func _build_save_dictionary() -> Dictionary:
	return {
		"current_event_name": _current_event.name if _current_event != null else "",
		"event_duration": _event_duration
	}

## Load the saved state of the economic event picker from persistent storage.
## This restores the current event and its remaining duration if available.
## If no saved event is found, it initializes the picker with no active event.
func load_data() -> void:
	if !SaveSystem.has(SaveName):
		return
	
	var data: Dictionary = SaveSystem.get_var(SaveName)
	var saved_event_name: String = data.get("current_event_name", "")
	_event_duration = data.get("event_duration", 0)
	
	# Restore the current event if it exists and has duration remaining
	if !saved_event_name.is_empty() and _event_duration > 0:
		if saved_event_name in _economic_events_dict:
			_current_event = _economic_events_dict[saved_event_name]
			_debug_log("Restored economic event: " + _current_event.name + " with " + str(_event_duration) + " blocks remaining")
			
			# Re-emit the event to apply its effects
			event_picked.emit(_current_event)
			main_event_bus.economy_event_picked.emit(_current_event)
		else:
			push_warning("Saved economic event '" + saved_event_name + "' not found in current events list. Clearing saved data.")
			_current_event = null
			_event_duration = 0
			save_data()
	else:
		_current_event = null
		_event_duration = 0

#endregion
