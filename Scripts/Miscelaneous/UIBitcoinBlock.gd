class_name UIBitcoinBlock extends Control

## Compact Bitcoin block card used by the network stream.

var block_data: Dictionary = {}

@onready var title_label: Label = %Title
@onready var miner_label: Label = %Miner
@onready var data_label: Label = %Data
@onready var timestamp_label: Label = %Timestamp
@onready var hash_label: Label = %Hash
@onready var previous_hash_label: Label = %PreviousHash
@onready var subsidy_label: Label = %Subsidy
@onready var block_panel: PanelContainer = $BlockPanel


func set_block_data(data: Dictionary) -> void:
	block_data = data
	if is_node_ready():
		_update_display()


func _update_display() -> void:
	if not is_node_ready():
		return
	title_label.text = "BLOCK // #%d" % block_data.get("height", 0)
	miner_label.text = block_data.get("miner", "Unknown")
	data_label.text = block_data.get("data", "")
	timestamp_label.text = _format_timestamp(block_data.get("timestamp", ""))
	hash_label.text = _format_hash(block_data.get("hash", ""))
	previous_hash_label.text = _format_hash(block_data.get("previous_hash", ""))
	subsidy_label.text = "%s BTC" % Utils.format_btc(block_data.get("subsidy", 0.0))


func _format_timestamp(timestamp: String) -> String:
	if timestamp.is_empty():
		return "Unknown"
	var time_dict := Time.get_datetime_dict_from_datetime_string(timestamp, false)
	if time_dict.is_empty():
		return timestamp
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		time_dict.year, time_dict.month, time_dict.day,
		time_dict.hour, time_dict.minute, time_dict.second
	]


func _format_hash(hash_str: String) -> String:
	if hash_str.is_empty():
		return "N/A"
	if hash_str.length() <= 16:
		return hash_str
	return "%s...%s" % [hash_str.substr(0, 8), hash_str.substr(-8)]


func get_block_data() -> Dictionary:
	return block_data.duplicate()


func create_from_game_data(height: int, miner_name: String, timestamp, block_hash: String, previous_hash: String, reward: float, data: String) -> void:
	set_block_data({
		"height": height,
		"miner": miner_name,
		"timestamp": timestamp,
		"hash": block_hash,
		"previous_hash": previous_hash,
		"subsidy": reward,
		"data": data,
	})


func set_special_styling(kind: String) -> void:
	if not is_node_ready():
		await ready
	match kind:
		"genesis":
			block_panel.self_modulate = Color("ffd166")
		"recent":
			block_panel.self_modulate = Color("b8fff4")
		_:
			block_panel.self_modulate = Color.WHITE
