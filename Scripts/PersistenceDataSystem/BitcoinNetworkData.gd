class_name BitcoinNetworkData extends Resource

@export var chain: Array = []
@export var height: int = -1
@export var block_subsidy: float = 0.0
@export var coins_lost: float = 0.0
@export var coins_in_circulation: float = 0.0

func _init(_chain = [], _height = -1, subsidy = 50_000.0, _coins_lost: float = 0.0, _coins_in_circulation: float = 0.0) -> void:
	chain = _chain
	height = _height
	block_subsidy = subsidy
	coins_lost = _coins_lost
	coins_in_circulation = _coins_in_circulation


func _to_string() -> String:
	var chain_str: String = ""
	for block in chain:
		chain_str += str(block) + "\n"
	return "BitcoinNetworkData:\nChain: %s" % chain_str + "\nHeight: %s" % height + "\nBlock Subsidy: %s" % block_subsidy + "\nCoins Lost: %s" % coins_lost + "\nCoins in Circulation: %s" % coins_in_circulation
