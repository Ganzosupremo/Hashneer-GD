class_name BitcoinBlock extends Resource
## This class represents a Bitcoin block in the blockchain.
##
## Each block contains a set of transactions (in this case, just dummy data), a timestamp, and a reference to the previous block.
## Blocks are mined by miners, who compete to solve complex mathematical problems.
## When a block is successfully mined, it is added to the blockchain, and the miner is rewarded with newly created bitcoins.

@export var miner: String = ""
@export var height: int = 0
@export var timestamp: String = ""
@export var data: String = ""
@export var previous_hash: String = ""
@export var block_hash: String = ""
@export var block_subsidy: float = 0.0
@export var mined: bool = false

func _init(_height: int = 0, _timestamp: String = "", _data: String = "", _miner: String = ""):
	height = _height
	timestamp = _timestamp
	data = _data
	miner = _miner
	block_hash = calculate_block_hash()
	
func calculate_block_hash() -> String:
	var sha = HashingContext.new()
	sha.start(HashingContext.HASH_SHA256)
	
	var hash_data = str_to_var(str(height) + timestamp + data + previous_hash)
	sha.update(var_to_bytes_with_objects(hash_data))
	
	var res = sha.finish()
	return res.hex_encode()
	
func _to_string() -> String:
	return "Height-%d" % height + "\n\nTimestamp-%s" % timestamp + "\n\nHash-%s" % block_hash + "\n\nPrevious Hash-%s" % previous_hash + "\n\nBlock Subsidy-%.2f" % block_subsidy