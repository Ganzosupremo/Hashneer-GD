extends Node2D
class_name Timechain

signal coin_subsidy_issued(btc_reward: float)
signal block_found(block: BitcoinBlock)
signal halving_occurred(new_subsidy: float)

const COIN: int = 100
const TOTAL_COINS: float = 2_100_000.0
const TOTAL_BLOCKS: int = 105
const TOTAL_HALVINGS: int = 10

var bitcoins_in_circulation: float = 0.0
var halving_interval: int = 2
var height: int = 0
var current_block_subsidy: float = 0.0
var coins_lost: float = 0.0
var coins_spent: float = 0.0
var chain: Array = []
var loaded: bool = false

# Deflation parameters
## The prices will be halved on every halving.
var deflation_rate: float = 0.5
## The total deflation since the begginning of times.
var total_deflation: float = 0.0

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	halving_occurred.connect(_on_halving_ocurred)

## __________________________PUBLIC FUNCTIONS________________________________

"""Mines and adds the new block to the chain"""
func mine_block(miner: String, new_block: BitcoinBlock = null) -> void:
	var block: BitcoinBlock = null
	if new_block != null:
		block = new_block
	else:
		block = create_block(miner)
	
	# Check if mining should be stopped right away
	if _should_stop_mining(block):
		return
	
	if chain.size() == 0:
		block.previous_hash = block.block_hash
		block.data = TEN
	else:
		block.previous_hash = get_latest_block().block_hash
	
	block.mined = true
	
	_add_block_to_chain(block)
	
	block.block_subsidy = _compute_block_reward()
	_issue_block_reward(miner, block.block_subsidy)
	block_found.emit(block)
	
	height += 1

func is_current_level_block(block: BitcoinBlock) -> bool:
	return block.height == GameManager._current_level


## Checks if a block has already been mined
## Returns true if the block has already been mined, false otherwise
## @param block The BitcoinBlock to check
## @return bool Whether the block has already been mined
func is_block_already_mined(block: BitcoinBlock) -> bool:
	if chain.size() == 0: return false
	if block.mined: return true
	
	for b in chain:
		if b.height == block.height:
			return true
	return false

func set_bitcoins_in_circulation(value: float) -> void:
	bitcoins_in_circulation += value

func add_coins_lost(value: float) -> void:
	coins_lost += value

func add_coins_spent(value: float) -> void:
	coins_spent += value

func get_block_by_id(id: int) -> BitcoinBlock:
	for b in chain:
		if b.height == id:
			return b
	return null

func get_block_by_hash(_hash: String) -> BitcoinBlock:
	for b in chain:
		if b.block_hash == _hash:
			return b
	return null

func get_latest_block() -> BitcoinBlock:
	return chain.back()

func create_block(miner: String) -> BitcoinBlock:
	return BitcoinBlock.new(height, Time.get_datetime_string_from_system(false, true), "Block Height: %s " % height + "Mined by: %s" % miner, miner)

func get_blockheight() -> int:
	return height

func get_total_deflation() -> float:
	return total_deflation

func get_total_bitcoins_in_circulation() -> float:
	return coins_lost + coins_spent + BitcoinWallet.get_bitcoin_balance()

func get_bitcoins_spent() -> float:
	return coins_spent

func get_block_subsidy() -> float:
	return current_block_subsidy

#region Private API

## Checks if the new block is valid and hasn't been mined before, returns true if block has
## already been mined before, false otherwise
func _should_stop_mining(new_block: BitcoinBlock) -> bool:
	# we don't check since it's the genesis block
	if chain.size() == 1: return false
	
	if new_block == null: return true
	if height > TOTAL_BLOCKS:
		return true
	
	return is_block_already_mined(new_block)

"""Adds the block to the chain."""
func _add_block_to_chain(new_block: BitcoinBlock) -> void:
	chain.append(new_block)

"""Issues the block subsidy to the miner that mined the block, i.e the player or the ai."""
func _issue_block_reward(miner: String, subsidy: float) -> void:
	if miner == "Player" or miner == "player":
		coin_subsidy_issued.emit(subsidy)
	elif miner == "AI":
		add_coins_lost(subsidy)

func _compute_block_reward() -> float:
	var halvings: int = height / halving_interval
	if halvings >= TOTAL_HALVINGS:
			return 0.0

	var remaining_supply: float = TOTAL_COINS - get_total_bitcoins_in_circulation()
	if remaining_supply <= 0.0:
			return 0.0

	var subsidy: float = TOTAL_COINS / (halving_interval * 2)
	subsidy /= pow(2.0, halvings)
	subsidy = min(subsidy, remaining_supply)

	var previous_subsidy: float = current_block_subsidy
	current_block_subsidy = subsidy

	if subsidy != previous_subsidy:
		halving_occurred.emit(subsidy)

	bitcoins_in_circulation += subsidy
	return subsidy



"""Called when a halving occurs"""
func _on_halving_ocurred(_new_subsidy: float) -> void:
	total_deflation += deflation_rate

#endregion

## __________________________________PERSISTENCE DATA FUNCTIONS______________________________________

func save_data():
	SaveSystem.set_var(GameManager.NetworkDataSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	return {
		"chain": chain,
		"height": height,
		"current_block_subsidy": current_block_subsidy,
		"coins_lost": coins_lost,
		"coins_spent": coins_spent
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
	current_block_subsidy = data["current_block_subsidy"]
	coins_lost = data["coins_lost"]
	coins_spent = data["coins_spent"]
	bitcoins_in_circulation = get_total_bitcoins_in_circulation()
	loaded = true


const TEN: String = "The Times: Chancellor on Brink of Second Bailout for Banks."
