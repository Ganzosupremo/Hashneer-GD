extends Node2D
class_name Timechain

signal reward_issued(btc_reward: float)
signal block_found(block: BitcoinBlock)

## A Bitcoin wallet, it will contain all player funds, fiat and bitcois.
@onready var bitcoin_wallet: BitcoinWallet = %BitcoinWallet

const COIN: int = 100
#change to 2.1 mill later
const TOTAL_COINS: float = 21_000_000.0
const TOTAL_BLOCKS: int = 105

var coins_in_circulation: float = 0.0
var halving_interval: int = 21
var height: int = 0
var current_reward: float = 0.0
var coins_lost: float = 0.0
var chain: Array = []
var loaded: bool = false

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready():
	chain.clear()

## ---------------------- PUBLIC FUNCTIONS ---------------------------

"""Mines and adds the new block to the chain"""
func mine_block(miner: String) -> void:
	var block: BitcoinBlock = create_block(miner)
	
	# Check if mining should be stopped right away
	if _check_mining_stopped(block):
		return
	
	if chain.size() == 0:
		block.previous_hash = block.block_hash
	else:
		block.previous_hash = get_latest_block().block_hash
	
	block.mined = true
	block.miner = miner
	
	_add_block_to_chain(block)
	
	block.reward = _get_block_subsidy()
	_issue_block_reward(miner, block.reward)
	emit_signal("block_found", block)
	
	height += 1


func get_latest_block() -> BitcoinBlock:
	return chain.back()

func create_block(miner: String) -> BitcoinBlock:
	return BitcoinBlock.new(height, Time.get_datetime_string_from_system(false, true), "Block Height: %s" % height + "Mined by: %s" % miner)

func get_blockheight() -> int:
	return height

## ---------------- INTERNAL FUNCTIONS ---------------------------------

func _create_genesis_block() -> void:
	var genesis_block: BitcoinBlock = BitcoinBlock.new(height, Time.get_datetime_string_from_system(false, true), "The Times: Chancellor on Brink of Second Bailout for Banks.")
	chain.append(genesis_block)
	mine_block("System")

"""
Checks if the new block is valid and hasn't been mined before, returns true if block has
already been mined before, false otherwise
"""
func _check_mining_stopped(new_block: BitcoinBlock) -> bool:
	# we don't check since it's the genesis block
	if chain.size() == 0: return false
	
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

"""Adds the block to the chain."""
func _add_block_to_chain(new_block: BitcoinBlock) -> void:
	chain.append(new_block)

"""Issues the block reward to the miner that mined the block, i.e the player or the ai."""
func _issue_block_reward(miner: String, reward: float) -> void:
	if miner == "Player" or miner == "player":
		self.bitcoin_wallet.add_bitcoin(reward)
		emit_signal("reward_issued", reward)
	elif miner == "AI":
		coins_lost += reward
		print("Reward issued to the AI")

func _get_block_subsidy() -> float:
	var halvings: int = height / halving_interval
	if (halvings >= 8):
		return 0.0
	
	var subsidy = 500 * COIN
	
	subsidy >>= halvings
	coins_in_circulation += subsidy
	
	if _exceeds_coin_limit_cap():
		print("Exceeds limit cap")
		return 0.0
	return subsidy

"""Returns true if the coins in circulation are more than the TOTAL_COINS"""
func _exceeds_coin_limit_cap() -> bool:
	if coins_in_circulation >= TOTAL_COINS:
		return true
	return false

## __________________________________PERSISTENCE DATA FUNCTIONS______________________________________

func save_data():
	var network_data = BitcoinNetworkData.new(chain, height, current_reward, coins_lost, coins_in_circulation)
	GameManager.game_data_to_save.bitcoin_network_data = network_data
	# SaveSystem.set_var("network_data", network_data)

func load_data():
	if loaded == true: return

	var net_data: BitcoinNetworkData = GameManager.get_resource_from_game_data("network_data")
	# # if !SaveSystem.has("network_data"): return
	# # var network_data: Dictionary = SaveSystem.get_var("network_data")
	# # var res: BitcoinNetworkData = Utils.dict_to_resource(network_data, BitcoinNetworkData.new())
	# # print("Loaded network data: {0}".format([res]))
	# # for i in res.chain.size():
	# # 	res.chain[i] = Utils.dict_to_resource(res.chain[i], BitcoinBlock.new())
	
	self.chain = net_data.chain
	self.height = net_data.height
	self.coins_lost = net_data.coins_lost
	self.current_reward = net_data.block_subsidy
	self.coins_in_circulation = net_data.coins_in_circulation
	loaded = true
