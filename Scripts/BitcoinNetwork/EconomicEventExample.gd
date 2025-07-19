extends Node
## Example script showing how to interact with the Economic Event System
##
## This script demonstrates how to:
## - Listen for economic events
## - Get information about active events
## - Manually control events for testing
## - Monitor event status

## Helper function for conditional debug logging
func _debug_log(message: String) -> void:
	if OS.is_debug_build():
		print_debug("[EconomicEventExample] " + message)

func _ready() -> void:	
	# Connect to event signals
	# event_picker.event_picked.connect(_on_event_picked)
	# event_picker.event_expired.connect(_on_event_expired)
	# Print current status
	_debug_log("Economic Event System initialized")
	_debug_log(EconomicEventsManager.get_debug_info())

func _on_event_picked(economic_event: EconomicEvent) -> void:
	_debug_log("🎲 New economic event picked: " + economic_event.name)
	_debug_log("   Impact: " + str(economic_event.impact))
	_debug_log("   Duration: " + str(economic_event.duration_in_blocks) + " blocks")
	_debug_log("   Type: " + str(economic_event.event_type))
	_debug_log("   Currency affected: " + str(economic_event.currency_affected))

func _on_event_expired(economic_event: EconomicEvent) -> void:
	_debug_log("⏰ Economic event expired: " + economic_event.name)
	_debug_log("   All upgrade costs should now return to their original values")

# Example functions you can call for testing
func force_economic_event() -> void:
	EconomicEventsManager.force_pick_event()

func force_market_crash() -> void:
	"""Force a market crash event for testing."""
	EconomicEventsManager.force_pick_event("Market Crash")

func show_current_status() -> void:
	"""Print the current event status."""
	_debug_log(EconomicEventsManager.get_debug_info())

func expire_current_event() -> void:
	"""Expire the current event manually."""
	EconomicEventsManager.force_expire_event()

func revert_all_effects() -> void:
	"""Manually revert all economic event effects for testing."""
	EconomicEventsManager.force_expire_event()

func set_event_chance(chance: float) -> void:
	"""Set the chance of events occurring (0.0 to 1.0)."""
	EconomicEventsManager.set_chance_of_event(chance)
	print_debug("Event chance set to: " + str(chance * 100) + "%")

func set_remaining_duration(new_duration: int) -> void:
	"""Set the remaining duration of the current event manually."""
	EconomicEventsManager.set_remaining_duration(new_duration)

# Example of how to integrate with other systems
func apply_event_to_system(system_name: String, event: EconomicEvent) -> void:
	"""Example of how to apply an event to a specific system."""
	match system_name:
		"SkillTree":
			# Apply to all skill nodes in the tree
			var skill_nodes = get_tree().get_nodes_in_group("SkillNodes")
			for node in skill_nodes:
				if node.has_method("apply_random_economic_event"):
					node.apply_random_economic_event(event)
		"Market":
			# Apply to market prices
			print_debug("Applying " + event.name + " to market system")
		"Currency":
			# Apply to currency exchange rates
			print_debug("Applying " + event.name + " to currency system")

# Console commands for debugging (can be called from in-game console if available)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				show_current_status()
			KEY_F2:
				force_economic_event()
			KEY_F3:
				expire_current_event()
			KEY_F4:
				set_event_chance(1.0)  # 100% chance for testing
			KEY_F5:
				set_event_chance(0.5)  # Back to 50%
			KEY_F6:
				revert_all_effects()  # New: manually revert all effects
			KEY_F7:
				set_remaining_duration(randi() % 10 + 1)  # Set remaining duration to 1-10 blocks for testing
			KEY_F9:
				EconomicEventsManager.force_decrease_remaining_duration()
