extends Resource
class_name BitcoinBlock

var miner: String = ""
var height: int = 0
var timestamp: String = ""
var data: String = ""
var previous_hash: String = "GENESIS BLOCK"
var block_hash: String = ""
var nonce: int = 0
var reward: float = 0.0
var mined: bool = false

func _init(_height: int, _timestamp: String, _data: String):
	height = _height
	print_debug("block height is: ", height)
	timestamp = _timestamp
	data = _data
	block_hash = calculate_block_hash()
	
func calculate_block_hash() -> String:
	var sha = HashingContext.new()
	sha.start(HashingContext.HASH_SHA256)
	
	var hash_data = str_to_var(str(height) + timestamp + data + previous_hash)
	sha.update(var_to_bytes_with_objects(hash_data))
	
	var res = sha.finish()
	return res.hex_encode()
	
func _to_string() -> String:
	return "Height: %s" % height + "\tTimestamp: %s" % timestamp + "\tHash: %s" % block_hash + "\tPrevious Hash: %s" % previous_hash + "\tData: %s" % data + "\tBlock Subsidy: %s" % str(reward)

