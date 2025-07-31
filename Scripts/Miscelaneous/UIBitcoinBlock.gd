class_name UIBitcoinBlock extends Control

## Bitcoin Block UI Display Component
## Displays block information in a modern Bitcoin-themed interface

# Block data structure
var block_data: Dictionary = {}

# UI References
@onready var title_label: Label = %Title
@onready var miner_label: Label = %Miner
@onready var data_label: Label = %Data
@onready var timestamp_label: Label = %Timestamp
@onready var hash_label: Label = %Hash
@onready var previous_hash_label: Label = %PreviousHash
@onready var subsidy_label: Label = %Subsidy

# func _ready() -> void:
# 	# Initialize with default values if no data is provided
# 	if block_data.is_empty():
# 		_set_default_data()
# 	_update_display()

## Sets default block data for testing/preview
func _set_default_data() -> void:
	block_data = {
		"height": 0,
		"miner": "Genesis Block",
		"timestamp": Time.get_datetime_string_from_system(),
		"hash": _generate_sample_hash(),
		"previous_hash": "0000000000000000000000000000000000000000000000000000000000000000",
		"subsidy": 512000,
		"data": "Genesis block - The Times 03/Jan/2009 Chancellor on brink of second bailout for banks",
	}

## Updates the block with new data
func set_block_data(data: Dictionary) -> void:
	block_data = data
	if is_node_ready():
		_update_display()

## Updates all UI elements with current block data
func _update_display() -> void:
	if not is_node_ready():
		return
		
	# Update title with block height
	title_label.text = "₿ Block #%d" % block_data.get("height", 0)
	
	# Update miner information
	var miner_name = block_data.get("miner", "Unknown")
	miner_label.text = miner_name
	
	# Update data
	var data: String = block_data.get("data", "")
	data_label.text = data
	
	# Update timestamp (format for readability)
	var timestamp = block_data.get("timestamp", "")
	timestamp_label.text = _format_timestamp(timestamp)
	
	# Update hash (truncated for display)
	var hash_str = block_data.get("hash", "")
	hash_label.text = _format_hash(hash_str)
	
	# Update previous hash (truncated for display)
	var prev_hash = block_data.get("previous_hash", "")
	previous_hash_label.text = _format_hash(prev_hash)
	
	# Update subsidy with proper Bitcoin formatting
	var subsidy = block_data.get("subsidy", 0.0)
	subsidy_label.text = _format_bitcoin_amount(subsidy)

## Formats timestamp for better readability
func _format_timestamp(timestamp: String) -> String:
	if timestamp.is_empty():
		return "Unknown"
	
	# Try to parse and format the timestamp
	var time_dict = Time.get_datetime_dict_from_datetime_string(timestamp, false)
	if time_dict.is_empty():
		return timestamp
	
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		time_dict.year, time_dict.month, time_dict.day,
		time_dict.hour, time_dict.minute, time_dict.second
	]

## Formats hash for display (shows first 8 and last 8 characters)
func _format_hash(hash_str: String) -> String:
	if hash_str.is_empty():
		return "N/A"
	
	if hash_str.length() <= 16:
		return hash_str
	
	return "%s...%s" % [hash_str.substr(0, 8), hash_str.substr(-8)]

## Formats Bitcoin amount with proper precision
func _format_bitcoin_amount(amount: float) -> String:
	return Utils.format_currency(amount, true)

## Generates a sample hash for testing
func _generate_sample_hash() -> String:
	var chars = "0123456789abcdef"
	var hash_str = ""
	
	# Bitcoin hashes start with zeros for valid blocks
	hash_str += "0000"
	
	# Generate random hex characters for the rest
	for i in range(60):
		hash_str += chars[randi() % chars.length()]
	
	return hash_str

## Gets the current block data
func get_block_data() -> Dictionary:
	return block_data.duplicate()

## Creates a block from game data (integration helper)
func create_from_game_data(height: int, miner_name: String, timestamp, _hash: String, previous_hash: String, reward: float, data: String) -> void:
	var new_data = {
		"height": height,
		"miner": miner_name,
		"timestamp": timestamp,
		"hash": _hash,
		"previous_hash": previous_hash,
		"subsidy": reward,
		"data": data
	}
	
	set_block_data(new_data)
