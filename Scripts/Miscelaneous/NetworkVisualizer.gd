class_name NetworkVisualizer extends Control

@onready var _coins_lost: Label = %CoinsLost
@onready var _coins_on_player: Label = %CoinsOnPlayer
@onready var _coins_left: Label = %CoinsLeft
@onready var _blocks_left: Label = %"Blocks Left"
@onready var _block_container: HBoxContainer = %BlockContainer
@onready var _empty_state_container: VBoxContainer = %EmptyStateContainer

@onready var _displayer_scene: PackedScene = preload("res://Scenes/Miscelaneous/UIBitcoinBlock.tscn")
@onready var skill_tree_scene: PackedScene = load("res://Scenes/SkillTreeSystem/SkillTree.tscn")

var _chain: Array = []
var _block_visualizers: Array[Control] = []

signal network_refreshed

func _ready() -> void:
	refresh_network_display()

func refresh_network_display() -> void:
	_update_chain_data()
	_update_statistics()
	_update_block_visualizers()
	_update_empty_state()
	network_refreshed.emit()

func _update_chain_data() -> void:
	_chain = BitcoinNetwork.chain.duplicate()
	_chain.reverse()  # Display from newest to oldest for better UX

func _update_statistics() -> void:
	# Update coin statistics
	var coins_lost: float = BitcoinNetwork.get_coins_lost()
	_coins_lost.text = "🔥 Coins Lost: %s BTC" % Utils.format_currency(coins_lost, true)
	
	var player_balance: float = BitcoinWallet.get_bitcoin_balance()
	_coins_on_player.text = "💰 Player Wallet: %s BTC" % Utils.format_currency(player_balance, true)
	
	var total_in_circulation: float = BitcoinNetwork.get_total_bitcoins_in_circulation()
	var left_to_mine: float = BitcoinNetwork.TOTAL_COINS - total_in_circulation
	_coins_left.text = "⛏️ Coins Left to Mine: %s BTC" % Utils.format_currency(left_to_mine, true)
	
	# Update block count
	var total_blocks: int = _chain.size()
	_blocks_left.text = "🧱 Total Blocks: %d" % total_blocks

func _update_block_visualizers() -> void:
	_clear_block_visualizers()
	
	if _chain.is_empty():
		return
	
	# Create visualizers for each block
	for i in range(_chain.size()):
		var block: BitcoinBlock = _chain[i]
		var block_visualizer: UIBitcoinBlock = _displayer_scene.instantiate()
		
		_block_container.add_child(block_visualizer)
		_block_visualizers.append(block_visualizer)
		
		# Set block data using the new UIBitcoinBlock interface
		block_visualizer.set_block_data({
			"height": block.height,
			"miner": block.miner,
			"timestamp": block.timestamp,
			"hash": block.block_hash,
			"previous_hash": block.previous_hash,
			"subsidy": block.block_subsidy,
			"data": block.data
		})
		
		# Add visual indicators for special blocks
		_apply_block_styling(block_visualizer, block, i)

func _apply_block_styling(visualizer: Control, block: BitcoinBlock, index: int) -> void:
	# Add special styling for genesis block
	if block.height == 0:
		if visualizer.has_method("set_special_styling"):
			visualizer.set_special_styling("genesis")
	
	# Add styling for recently mined blocks
	elif index < 3:  # Last 3 blocks
		if visualizer.has_method("set_special_styling"):
			visualizer.set_special_styling("recent")

func _clear_block_visualizers() -> void:
	for visualizer in _block_visualizers:
		if is_instance_valid(visualizer):
			visualizer.queue_free()
	_block_visualizers.clear()

func _update_empty_state() -> void:
	var has_blocks: bool = not _chain.is_empty()
	_empty_state_container.visible = not has_blocks
	_block_container.get_parent().visible = has_blocks

func get_network_statistics() -> Dictionary:
	return {
		"total_blocks": _chain.size(),
		"coins_lost": BitcoinNetwork.get_coins_lost(),
		"player_balance": BitcoinWallet.get_bitcoin_balance(),
		"total_in_circulation": BitcoinNetwork.get_total_bitcoins_in_circulation(),
		"coins_left_to_mine": BitcoinNetwork.TOTAL_COINS - BitcoinNetwork.get_total_bitcoins_in_circulation(),
		"last_block_height": _chain[0].height if not _chain.is_empty() else -1,
		"last_block_timestamp": float(_chain[0].timestamp) if not _chain.is_empty() else 0.0
	}

func _exit_tree() -> void:
	_clear_block_visualizers()


func _on_return_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(skill_tree_scene)
