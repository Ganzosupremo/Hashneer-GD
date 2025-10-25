class_name CustomDebugLogger extends Node
## DebugLogger - Centralized debug logging system
## 
## This system provides conditional debug logging that only outputs to console
## when running in debug builds (inside Godot editor) and remains silent
## in release builds (exported games).
##
## Usage:[br]
## - DebugLogger.debug("Your message")[br]
## - DebugLogger.warn("Warning message")[br]
## - DebugLogger.error("Error message")[br]
## - DebugLogger.log_event("Economic event picked", event_data)[br]

## Log levels for different types of messages
enum LogLevel {
	DEBUG, ## Debug messages, useful for development
	INFO, ## Informational messages, general updates
	WARNING, ## Warning messages, potential issues
	ERROR ## Error messages, critical issues
}

## Whether debug logging is enabled (automatically determined)
var debug_enabled: bool = false

## Whether to include timestamps in log messages
var include_timestamps: bool = true

## Whether to include the calling script name in log messages
var include_script_name: bool = true

func _ready() -> void:
	# Determine if we're running in debug mode (inside Godot editor)
	debug_enabled = OS.is_debug_build() and Engine.is_editor_hint() == false and OS.has_feature("editor")
	
	# Alternative check: if the above doesn't work reliably, use this:
	if not debug_enabled:
		debug_enabled = OS.is_debug_build()
	
	if debug_enabled:
		debug("DebugLogger initialized - Debug logging ENABLED")

## Main logging function with level support
## This function formats the message with a timestamp and script name if enabled,
## and prints it to the console based on the log level.[br]
## [param message] The message to log[br]
## [param level] The log level (default is LogLevel.DEBUG)[br]
## [param script_name] The name of the script calling this function (optional)
func log_with_level(message: String, level: LogLevel = LogLevel.DEBUG, script_name: String = "") -> void:
	if not debug_enabled:
		return
	
	var formatted_message = _format_message(message, level, script_name)
	
	match level:
		LogLevel.DEBUG:
			print_debug(formatted_message)
		LogLevel.INFO:
			print(formatted_message)
		LogLevel.WARNING:
			push_warning(formatted_message)
		LogLevel.ERROR:
			push_error(formatted_message)

## Simple debug log (equivalent to print_debug)
func debug(message: String, script_name: String = "") -> void:
	log_with_level(message, LogLevel.DEBUG, script_name)

## Info level logging
func info(message: String, script_name: String = "") -> void:
	log_with_level(message, LogLevel.INFO, script_name)

## Warning level logging
func warn(message: String, script_name: String = "") -> void:
	log_with_level(message, LogLevel.WARNING, script_name)

## Error level logging
func error(message: String, script_name: String = "") -> void:
	log_with_level(message, LogLevel.ERROR, script_name)

## Log economic events with structured data.
## [param event_type]: The type of the event (e.g., "EconomicEventPicked")
## [param event_data]: A dictionary containing relevant data about the event.
## This method formats the event data and logs it with the appropriate level.
func log_event(event_type: String, event_data: Dictionary = {}) -> void:
	if not debug_enabled:
		return
	
	var message = "EVENT: " + event_type
	if not event_data.is_empty():
		message += " | Data: " + str(event_data)
	
	log_with_level(message, LogLevel.INFO, "EconomicEvents")

## Log with automatic script name detection.
## This method captures the calling script's name and logs the message with the specified level.
## [param message]: The message to log.[br]
## [param calling_script]: The script object that is calling this method.[br]
## [param level]: The log level (default is LogLevel.DEBUG).
func log_from_script(message: String, calling_script: Object, level: LogLevel = LogLevel.DEBUG) -> void:
	var script_name = ""
	if calling_script != null:
		var script_path = calling_script.get_script().resource_path
		script_name = script_path.get_file().get_basename()
	
	log_with_level(message, level, script_name)

# Format the log message with timestamp and script name
func _format_message(message: String, level: LogLevel, script_name: String = "") -> String:
	var formatted = ""
	
	# Add timestamp if enabled
	if include_timestamps:
		var time = Time.get_datetime_dict_from_system()
		formatted += "[%02d:%02d:%02d] " % [time.hour, time.minute, time.second]
	
	# Add log level
	var level_str = ""
	match level:
		LogLevel.DEBUG:
			level_str = "[DEBUG]"
		LogLevel.INFO:
			level_str = "[INFO]"
		LogLevel.WARNING:
			level_str = "[WARN]"
		LogLevel.ERROR:
			level_str = "[ERROR]"
	
	formatted += level_str + " "
	
	# Add script name if provided and enabled
	if include_script_name and not script_name.is_empty():
		formatted += "[" + script_name + "] "
	
	# Add the actual message
	formatted += message
	
	return formatted

## Convenience methods for common economic event logging.
## These methods provide a structured way to log specific economic events.
## [param event]: The EconomicEvent object to log.
func log_economic_event_picked(event: EconomicEvent) -> void:
	if event == null:
		return
	
	var event_data = {
		"name": event.name,
		"type": str(event.event_type),
		"impact": event.impact,
		"currency": str(event.currency_affected),
		"duration": event.duration_in_blocks
	}
	log_event("EconomicEventPicked", event_data)

## Log when an economic event expires.
## [param event]: The EconomicEvent object that expired.[br]
## This method formats the event data and logs it with the appropriate level.
func log_economic_event_expired(event: EconomicEvent) -> void:
	if event == null:
		return
	
	var event_data = {
		"name": event.name,
		"type": str(event.event_type)
	}
	log_event("EconomicEventExpired", event_data)

## Log when a skill node is upgraded.
## [param skill_name]: The name of the skill being upgraded.[br]
## [param level]: The new level of the skill.[br]
## [param cost]: The cost of the upgrade.
func log_skill_node_upgrade(skill_name: String, level: int, cost: float) -> void:
	var upgrade_data = {
		"skill": skill_name,
		"new_level": level,
		"cost": cost
	}
	log_event("SkillUpgrade", upgrade_data)

## Log when a skill's cost is reverted.
## [param skill_name]: The name of the skill whose cost is reverted.[br]
## [param original_cost]: The original cost of the skill.[br]
## [param modified_cost]: The modified cost of the skill.
func log_cost_revert(skill_name: String, original_cost: float, modified_cost: float) -> void:
	var revert_data = {
		"skill": skill_name,
		"original_cost": original_cost,
		"modified_cost": modified_cost
	}
	log_event("CostReverted", revert_data)

## Enable or disable debug logging manually (useful for testing)
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	if enabled:
		debug("Debug logging manually ENABLED")
	else:
		print("Debug logging manually DISABLED") # Use print to ensure this message appears

## Check if debug logging is currently enabled
func is_debug_enabled() -> bool:
	return debug_enabled

## Get a formatted string with current debug status
func get_debug_status() -> String:
	var status = "=== Debug Logger Status ===\n"
	status += "Debug Enabled: " + str(debug_enabled) + "\n"
	status += "Is Debug Build: " + str(OS.is_debug_build()) + "\n"
	status += "Is Editor Hint: " + str(Engine.is_editor_hint()) + "\n"
	status += "Has Editor Feature: " + str(OS.has_feature("editor")) + "\n"
	status += "Include Timestamps: " + str(include_timestamps) + "\n"
	status += "Include Script Names: " + str(include_script_name) + "\n"
	return status
