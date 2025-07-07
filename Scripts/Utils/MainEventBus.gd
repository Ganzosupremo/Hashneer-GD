class_name MainEventBus extends Resource


signal level_completed(args: LevelCompletedArgs)
signal currency_changed(currency: Constants.CurrencyType)

func emit_level_completed(_code: String) -> void:
	level_completed.emit(LevelCompletedArgs.new(_code))

func emit_currency_changed(_currency: Constants.CurrencyType) -> void:
	currency_changed.emit(_currency)

class LevelCompletedArgs:
	extends Object
	
	func _init(_code: String) -> void:
		code = _code
	
	var code: String = ""
