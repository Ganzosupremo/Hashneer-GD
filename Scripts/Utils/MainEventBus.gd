class_name MainEventBus extends Resource


signal level_completed(args: LevelCompletedArgs)
signal bullet_pool_setted(args: BulletPoolSettedArgs)
signal use_btc_toggled_ui(toggled_on: bool)

func emit_bullet_pool_setted(_pools: Dictionary) -> void:
	print_debug("Pools Setted")
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
