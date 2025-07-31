class_name Timechain extends Node2D
## Timechain is the main class for managing the Bitcoin network in the game.
##
## It handles block mining, economic events, and the overall state of the Bitcoin network.
## It is responsible for maintaining the blockchain, issuing block rewards, and managing the economic event system.
## It also integrates with the game's save system to persist the state of the network across sessions.

## Signal emitted when a new block subsidy is issued, i.e. when a new block is mined.
signal coin_subsidy_issued(btc_reward: float)
## This signal is emitted when a new block is mined and added to the blockchain.
signal block_found(block: BitcoinBlock)
## This signal is emitted when a halving occurs, indicating the new block subsidy.
signal halving_occurred(new_subsidy: float)

## @deprecated: The multiplier for the block subsidy.
## This is used to calculate the block reward based on the current height of the blockchain.
## In the real Bitcoin network, this is set to 100,000,000 satoshis per bitcoin.
const COIN_SUBSIDY_MULTIPLIER: int = 100
## The total number of bitcoins that will ever be created in the game.
## This is a fixed value that represents the maximum supply of bitcoins.
## In the real Bitcoin network, this is capped at 21 million bitcoins.
const TOTAL_COINS: float = 2_100_000.0
## @deprecated: The total number of blocks in the game, which is used to determine the end of the game.
## This is a fixed value that represents the total number of blocks that can be mined.
const TOTAL_BLOCKS: int = 21
## The total number of halvings that will occur in the game.
## This is a fixed value that represents the number of times the block subsidy will be halved.
## In the real Bitcoin network, this occurs approximately every 4 years.
const TOTAL_HALVINGS: int = 10

const _API_REQUEST: String = "https://bitcoinexplorer.org/api/quotes/all"
var _request: HTTPRequest = null
var quotes_for_fun: Array = []

## The current amount of bitcoins in circulation.
var bitcoins_in_circulation: float = 0.0
## The interval at which halvings occur, in blocks.
## This is used to determine when the block subsidy should be halved.
var halving_interval: int = 2
## The current height of the blockchain, which is the number of blocks that have been mined.
## This is used to track the progress of the blockchain and determine when halvings occur.
## It starts at 0 and increments with each new block mined.
## It is also used to determine the current block subsidy.
var height: int = 0
## The current block subsidy, which is the amount of bitcoins awarded to the miner of a new block.
## This value is calculated based on the current height of the blockchain and the halving interval.
var current_block_subsidy: float = 0.0
## The total amount of bitcoins lost in the game, which is used to track the economic impact of events.
## This value is updated whenever a block is mined and the block subsidy is issued.
var coins_lost: float = 0.0
## The total amount of bitcoins spent in the game, which is used to track the economic impact of transactions.
## This value is updated whenever the player spends bitcoins in the game.
var coins_spent: float = 0.0
## The chain of blocks in the Bitcoin network.
## This is an array that holds all the blocks that have been mined in the game.
## It starts with the genesis block and grows as new blocks are mined. See [BitcoinBlock] for details.
var chain: Array = []

var _loaded: bool = false

# Deflation parameters
## The prices will be halved on every halving.
var deflation_rate: float = 0.5

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]


func _ready() -> void:
	_request = HTTPRequest.new()
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	_request.request(_API_REQUEST)

#region Public API

## Mines a new block in the Bitcoin network.
## This method creates a new block, checks if it can be mined, and adds it to the blockchain.
## It also issues the block reward to the miner and emits the [signal block_found] signal.[br]
## [param miner]: The name of the miner who mined the block (e.g., "Player" or "AI").[br]
## [param new_block]: An optional BitcoinBlock object to use instead of creating a new one. Passed by the [miner].
## If provided, this block will be used for mining; otherwise, a new block will be created.
## @return void
func mine_block(miner: String, new_block: BitcoinBlock = null) -> void:
	var block: BitcoinBlock = null
	if new_block != null:
		block = new_block
	else:
		block = create_block(miner)
	
	# Check if mining should be stopped right away
	if should_stop_mining(block):
		return
	
	if chain.size() == 0:
		block.previous_hash = block.block_hash
	else:
		block.previous_hash = get_latest_block().block_hash
	
	block.mined = true
	
	_add_block_to_chain(block)
	
	block.block_subsidy = _compute_block_reward()
	_issue_block_reward(miner, block.block_subsidy)
	block_found.emit(block)
	
	height += 1

## Checks if the current level block matches the specified block.
## Returns [code]true[/code] if the block matches the current level, [code]false[/code] otherwise.[br]
## [param block]: The BitcoinBlock to check against the current level[br]
## @return bool Whether the block matches the current level.
func is_current_level_block(block: BitcoinBlock) -> bool:
	return block.height == GameManager._current_level


## Checks if a block has already been mined
## Returns [code]true[/code] if the block has already been mined, [code]false[/code] otherwise.[br]
## [param block]: The BitcoinBlock to check[br]
## @return bool Whether the block has already been mined
func is_block_already_mined(block: BitcoinBlock) -> bool:
	if chain.size() == 0: return false
	if block.mined: return true
	
	for b in chain:
		if b.height == block.height:
			return true
	return false

## Sets the total bitcoins in circulation.
func set_bitcoins_in_circulation(value: float) -> void:
	bitcoins_in_circulation += value

## Adds the specified amount of coins lost to the total coins lost in the game.
func add_coins_lost(value: float) -> void:
	coins_lost += value

## Adds the specified amount of coins spent to the total coins spent in the game.
func add_coins_spent(value: float) -> void:
	coins_spent += value

## Gets a block by its ID (height).
func get_block_by_id(id: int) -> BitcoinBlock:
	for b in chain:
		if b.height == id:
			return b
	return null

## Checks if a specific level has been mined.
## Returns [code]true[/code] if the level has been mined, [code]false[/code] otherwise.[br]
## [param level_index]: The index of the level to check[br]
## @return bool Whether the level has been mined.
func is_level_mined(level_index: int) -> bool:
	return get_block_by_id(level_index) != null

## Gets the block by its hash.
## Returns the BitcoinBlock object if found, or null if not found.[br]
## [param _hash]: The hash of the block to find[br]
func get_block_by_hash(_hash: String) -> BitcoinBlock:
	for b in chain:
		if b.block_hash == _hash:
			return b
	return null

## Gets the latest block in the blockchain.
## Returns the last BitcoinBlock in the chain, or null if the chain is empty.[br]
## @return BitcoinBlock The latest block in the blockchain.
func get_latest_block() -> BitcoinBlock:
	return chain.back()

## Creates a new BitcoinBlock with the current height and timestamp.
## This method generates a new block with the current height, timestamp, and miner's name.
func create_block(miner: String) -> BitcoinBlock:
	return BitcoinBlock.new(height, Time.get_datetime_string_from_system(false, true), quotes_for_fun[randi() % quotes_for_fun.size()], miner)

## Gets the current block height.
## This method returns the current height of the blockchain, which is the number of blocks that have been mined so far.
## It is used to track the progress of the blockchain and determine when halvings occur.
## @return int The current block height.
func get_blockheight() -> int:
	return height

## Gets the deflation multiplier based on the current block height.
## This method calculates the deflation multiplier based on the number of halvings that have occurred.
## It uses the formula: `pow(1.0 - deflation_rate, halvings)` to determine the multiplier.
## It is used to adjust prices and economic events based on the current state of the blockchain.[br]
## @return float The deflation multiplier based on the current block height.
func get_deflation_multiplier() -> float:
	var halvings: int = height / halving_interval
	return pow(1.0 - deflation_rate, halvings)

## Gets the total bitcoins in circulation, including the current block subsidy.
## This method calculates the total bitcoins in circulation by adding the coins lost, coins spent, and the current block subsidy.
## It is used to track the overall supply of bitcoins in the game.
func get_total_bitcoins_in_circulation() -> float:
	return coins_lost + coins_spent + BitcoinWallet.get_bitcoin_balance()

## Gets the total bitcoins spent in the game.
func get_bitcoins_spent() -> float:
	return coins_spent

## Gets the current block subsidy.
func get_block_subsidy() -> float:
	return current_block_subsidy

## Returns the total coins lost in the game.
func get_coins_lost() -> float:
	return coins_lost

#endregion

#region Private API

## Checks if the new block is valid and hasn't been mined before, returns [code]true[/code] if block has
## already been mined before, [code]false[/code] otherwise
func should_stop_mining(new_block: BitcoinBlock) -> bool:
	# we don't check since it's the genesis block
	if chain.size() == 1: return false
	
	if new_block == null: return true
	if height > TOTAL_BLOCKS:
		return true
	
	return is_block_already_mined(new_block)

## [color=red]Note: For internal use only.[/color][br]
## Adds a new block to the blockchain.
func _add_block_to_chain(new_block: BitcoinBlock) -> void:
	chain.append(new_block)

## [color=red]Note: For internal use only.[/color][br]
## Issues the block subsidy to the miner that mined the block, i.e the player or the ai.[br]
## [param miner]: The name of the miner who mined the block (e.g., "Player" or "AI").[br]
## [param subsidy]: The amount of bitcoins to issue as a reward for mining the block.[br]
## This method emits the [signal coin_subsidy_issued] signal to notify the game systems about the new block subsidy.
## It also updates the total bitcoins in circulation and the coins lost in the game.
func _issue_block_reward(miner: String, subsidy: float) -> void:
	if miner == "Player" or miner == "player":
		coin_subsidy_issued.emit(subsidy)
	elif miner == "AI":
		add_coins_lost(subsidy)

## [color=red]Note: For internal use only.[/color][br]
## Computes the block reward based on the current height and halving interval.
## This method calculates the block subsidy based on the number of halvings that have occurred.
## It uses the formula: `TOTAL_COINS / (halving_interval * 2)` to determine the initial subsidy,
## and then halves it for each halving that has occurred.
## It also emits the [signal halving_occurred] signal when a halving occurs.
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

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		DebugLogger.error("Failed to fetch quotes from API. Response code: %d" % response_code)
		return
	var json: JSON = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		DebugLogger.error("Failed to parse JSON response from API.")
		return
	var json_data: Array = json.data
	quotes_for_fun = []
	for i in range(json_data.size()):
		var quote_data: Dictionary = json_data[i]
		if quote_data.has("text"):
			quotes_for_fun.append(quote_data["text"])

#endregion


## Saves the network data to the save system.
## This method persists the current state of the blockchain, including the chain, height, current block subsidy,
## coins lost, and coins spent.
## It uses the [SaveSystem] to store the data in a persistent format.
## This allows the game to restore the network state when loading a saved game or starting a new session.
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

## Loads the network data from the save system.
## This method retrieves the saved blockchain data and initializes the network state.
func load_data():
	if _loaded: return
	
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
	_loaded = true