extends Node2D
class_name Timechain

signal reward_issued(btc_reward: float)
signal block_found(block: BitcoinBlock)
signal halving_occurred(new_subsidy: float)

const COIN: int = 100
#change to 2.1 mill later
const TOTAL_COINS: float = 21_000_000.0
const TOTAL_BLOCKS: int = 105

var bitcoins_in_circulation: float = 0.0
var halving_interval: int = 21
var height: int = 0
var current_reward: float = 0.0
var coins_lost: float = 0.0
var chain: Array = []
var loaded: bool = false

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

## ---------------------- PUBLIC FUNCTIONS ---------------------------

"""Mines and adds the new block to the chain"""
func mine_block(miner: String, new_block: BitcoinBlock = null) -> void:
	var block: BitcoinBlock = null
	if new_block != null:
		block = new_block
	else:
		block = create_block(miner)
	
	# Check if mining should be stopped right away
	if _should_stop_mining(block):
		print_debug("Block already mined. H: ", block.height)
		return
	
	if chain.size() == 0:
		block.previous_hash = block.block_hash
		block.data = TEN
	else:
		block.previous_hash = get_latest_block().block_hash
	
	block.mined = true
	block.miner = miner
	
	_add_block_to_chain(block)
	
	block.reward = _get_block_subsidy()
	_issue_block_reward(miner, block.reward)
	print_debug("Block found")
	block_found.emit(block)
	
	height += 1

func is_current_level_block(block: BitcoinBlock) -> bool:
	return block.height == GameManager.current_level

func get_block_by_id(id: int) -> BitcoinBlock:
	return chain[id]

func get_latest_block() -> BitcoinBlock:
	return chain.back()

func create_block(miner: String) -> BitcoinBlock:
	return BitcoinBlock.new(height, Time.get_datetime_string_from_system(false, true), "Block Height: %s " % height + "Mined by: %s" % miner)

func get_blockheight() -> int:
	return height

## ---------------- INTERNAL FUNCTIONS ---------------------------------

## Checks if the new block is valid and hasn't been mined before, returns true if block has
## already been mined before, false otherwise
func _should_stop_mining(new_block: BitcoinBlock) -> bool:
	# we don't check since it's the genesis block
	if chain.size() == 1: return false
	
	if height > TOTAL_BLOCKS:
		return true
	
	if new_block.mined:
		return true
	# Check if the block has already been mined
	for block in chain:
		if block.height == new_block.height:
			return true
	
	return false

"""Adds the block to the chain."""
func _add_block_to_chain(new_block: BitcoinBlock) -> void:
	chain.append(new_block)

"""Issues the block reward to the miner that mined the block, i.e the player or the ai."""
func _issue_block_reward(miner: String, reward: float) -> void:
	if miner == "Player" or miner == "player":
		reward_issued.emit(reward)
	elif miner == "AI":
		coins_lost += reward
		print("Reward issued to the AI")

func _get_block_subsidy() -> float:
	var halvings: int = height / halving_interval
	if (halvings > 5):
		return 0.0
	
	var subsidy = 500 * COIN
	var previous_subsidy: float = subsidy
	
	subsidy >>= halvings
	bitcoins_in_circulation += subsidy

	if subsidy != previous_subsidy:
		halving_occurred.emit(subsidy)
	
	if _exceeds_coin_limit_cap():
		print("Exceeds limit cap")
		return 0.0
	return subsidy

"""Returns true if the coins in circulation are more than the TOTAL_COINS"""
func _exceeds_coin_limit_cap() -> bool:
	if bitcoins_in_circulation >= TOTAL_COINS:
		return true
	return false

## __________________________________PERSISTENCE DATA FUNCTIONS______________________________________

func save_data():
	SaveSystem.set_var(GameManager.NetworkDataSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	return {
		"chain": chain,
		"height": height,
		"current_reward": current_reward,
		"coins_lost": coins_lost,
		"bitcoins_in_circulation": bitcoins_in_circulation
	}

func load_data():
	if loaded: return
	
	if !SaveSystem.has(GameManager.NetworkDataSaveName): return
	
	var data: Dictionary = SaveSystem.get_var(GameManager.NetworkDataSaveName)
	var saved_chain: Array = data["chain"]
	
	for i in saved_chain.size():
		saved_chain[i] = Utils.build_res_from_dictionary(saved_chain[i], BitcoinBlock.new())
	
	chain = saved_chain.duplicate(true)
	height = data["height"]
	current_reward = data["current_reward"]
	coins_lost = data["coins_lost"]
	bitcoins_in_circulation = data["bitcoins_in_circulation"]
	loaded = true



const TEN: String = "The Times: Chancellor on Brink of Second Bailout for Banks."
