class_name MainEventBus extends Resource
## This is the main event bus for the game, used to emit and listen to events across different systems.
##
## This bus is designed to be a central hub for communication between different parts of the game, such as UI, gameplay, and audio.


## This signal is emitted when a new economic event is picked. see [EconomicEvent] for details.
signal economy_event_picked(event: EconomicEvent)
## This signal is emitted when an economic event expires. see [EconomicEvent] for details.
signal economy_event_expired(event: EconomicEvent)
## This signal is emitted when a level is completed. see [LevelCompletedArgs] for details.
signal level_completed(args: LevelCompletedArgs)
## This signal is emitted when the currency changes.
## This is used to notify systems that need to update their UI or logic based on the current currency.
## See [enum Constants.CurrencyType] for available currency types.
signal currency_changed(currency: Constants.CurrencyType)

func emit_level_completed(_code: String) -> void:
	level_completed.emit(LevelCompletedArgs.new(_code))

func emit_currency_changed(_currency: Constants.CurrencyType) -> void:
	currency_changed.emit(_currency)

func emit_economy_event_picked(_event: EconomicEvent) -> void:
	DebugLogger.info("Emitting economic event picked: " + _event.name)
	economy_event_picked.emit(_event)

func emit_economy_event_expired(_event: EconomicEvent) -> void:
	DebugLogger.info("Emitting economic event expired: " + _event.name)
	economy_event_expired.emit(_event)

class LevelCompletedArgs:
	extends Object
	
	func _init(_code: String) -> void:
		code = _code
	
	var code: String = ""
