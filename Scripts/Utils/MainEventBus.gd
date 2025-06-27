class_name MainEventBus extends Resource


signal level_completed(args: LevelCompletedArgs)
signal bullet_pool_setted(args: BulletPoolSettedArgs)
signal currency_changed(currency: Constants.CurrencyType)

func emit_bullet_pool_setted(_pools: Dictionary) -> void:
	bullet_pool_setted.emit(BulletPoolSettedArgs.new(_pools))

class LevelCompletedArgs:
	extends Object
	
	func _init(_code: String) -> void:
		code = _code
	
	var code: String = ""

class BulletPoolSettedArgs:
	extends Object
	
	var pools: Dictionary
	
	func _init(_pools: Dictionary) -> void:
		pools = _pools
