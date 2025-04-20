class_name MainEventBus extends Resource


signal level_completed(args: LevelCompletedArgs)


class LevelCompletedArgs:
	extends Object
	
	func _init(_code: String) -> void:
		code = _code
	
	var code: String = ""
