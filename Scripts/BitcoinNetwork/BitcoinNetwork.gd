extends Node2D
class_name Blockchain

signal reward_issued(btc_reward: float)
signal block_core_destroyed(miner: String, block: BitcoinBlock)

const COIN: int = 100
#change to 2.1 mill later
const TOTAL_COINS: float = 21_000_000.0
const TOTAL_BLOCKS: int = 105

var coins_in_circulation: float = 0.0
var halving_interval: int = 21
var height: int = -1
var current_reward: float = 0.0
var coins_lost: float = 0.0
var chain: Array = []
var loaded: bool = false

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready():
	chain.clear()
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
	if _check_mining_stopped(block, genesis):
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
func _check_mining_stopped(new_block: BitcoinBlock, genesis: bool = false) -> bool:
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

func get_latest_block():
	if chain.size() > 0:
		return chain.back()
	else: return null

func get_block_subsidy() -> float:
	var halvings: int = height / halving_interval
	if (halvings >= 8):
		return 0
	
	var subsidy = 500 * COIN
	
	subsidy >>= halvings
	return subsidy

func save_data():
	var network_data = BitcoinNetworkData.new(chain, height, current_reward, coins_lost, coins_in_circulation)
	SaveSystem.set_var("network_data", network_data)

func load_data():
	if loaded == true: return
	
	var network_data = SaveSystem.get_var("network_data")
	
	var res: BitcoinNetworkData = build_res(network_data)

	for i in res.chain.size():
		res.chain[i] = build_res(res.chain[i], 1)
	
	
	self.chain = res.chain
	self.height = res.height
	self.coins_lost = res.coins_lost
	self.current_reward = res.block_subsidy
	self.coins_in_circulation = res.coins_in_circulation
	loaded = true

func build_res(data: Dictionary, index: int = -1):
	var res
	if index == -1:
		res = BitcoinNetworkData.new()
	else:
		res = BitcoinBlock.new()
	
	for i in range(data.size()):
		var key = data.keys()[i]
		var value = data.values()[i]
		res.set(key, value)
	print("resource builded")
	return res
