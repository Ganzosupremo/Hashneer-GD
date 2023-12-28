extends Node2D
class_name Blockchain

signal reward_issued(btc_reward: float)
signal block_core_destroyed(miner: String, block: BitcoinBlock)

const COIN: int = 100
const TOTAL_COINS: float = 2_100_000.0
const TOTAL_BLOCKS: int = 105

var halving_interval: int = 21
var height: int = -1
var current_reward: float = 0.0
var coins_lost: float = 0.0
var chain: Array = []

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready():
	current_reward = get_block_subsidy()
	create_genesis_block()
	connect("block_core_destroyed", on_block_core_destroyed)

func on_block_core_destroyed(_chain_tip: int, miner: String, block: BitcoinBlock):
	mine_block(miner, block)

func create_genesis_block() -> void:
	var genesis_block: BitcoinBlock = BitcoinBlock.new(height, Time.get_datetime_string_from_system(false, true), "Genesis Block")
	chain.append(genesis_block)
	mine_block("Genesis", genesis_block, true)

## mines and adds the new block to the chain
func mine_block(miner: String, block: BitcoinBlock, genesis: bool = false) -> bool:
	# Check if mining should be stopped right away
	if check_mining_stopped(block, genesis):
		return false
	
	height += 1
	
	block.previous_hash = get_latest_block().block_hash
	block.mined = true
	
	block.miner = miner
	
	if !genesis: 
		_add_block_to_chain(block)
	
	block.reward = _issue_block_reward(miner)
	return true

"""
Checks if the new block is valid and hasn't been mined before, returns true if block has
already been mined before, false otherwise
"""
func check_mining_stopped(new_block: BitcoinBlock, genesis: bool = false) -> bool:
	# we don't check since it's the genesis block
	if genesis: return false
	
	if height > TOTAL_BLOCKS:
		return true
	
	if new_block.mined:
		return true
	
	var last_block = get_latest_block()
	if last_block == null: last_block = new_block

	# Check if the new block is at the same height as the last block in the chain
	if new_block.height == last_block.height or new_block.height <= last_block.height:
		return true
	
	return false

## adds the block to the chain, this method should not be called outside the mine_block() function
func _add_block_to_chain(new_block: BitcoinBlock) -> void:
	chain.append(new_block)

## issues the block reward to the miner that mined the block, i.e the player or the ai.
## should not be called outside the mine_block function
func _issue_block_reward(miner: String) -> float:
	var btc_reward = get_block_subsidy()
	
	if miner == "player":
		emit_signal("reward_issued", btc_reward)
	elif miner == "AI":
		coins_lost += btc_reward
		print("Reward issued to the AI")

	return btc_reward

func get_latest_block() -> BitcoinBlock:
	if chain.size() > 0:
		return chain[chain.size() - 1]
	else: return null

func get_block_subsidy() -> float:
	var halvings: int = height / halving_interval
	if (halvings >= 8):
		return 0
	
	var subsidy = 5000 * COIN
	
	subsidy >>= halvings
	return subsidy

func save() -> Dictionary:
	return {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"Current Height: ": height,
		"Current Block Subsidy: ": current_reward,
		"Coins Lost: ": coins_lost,
		"Chain: ": chain,
	}

func save_data(data: GameData):
	var network_data = GameData.BitcoinNetworkData.new()
	network_data.chain = self.chain
	network_data.height = self.height
	network_data.coins_lost = self.coins_lost
	network_data.block_subsidy = self.current_reward
	data.data["bitcoin_network_data"] = network_data

func load_data(data: GameData):
	var network_data = data.data["bitcoin_network_data"]
	
	self.chain = network_data.chain
	self.height = network_data.height
	self.coins_lost = network_data.coins_lost
	self.current_reward = network_data.block_subsidy
