extends Node
## Achievements tracks goals the player reaches and shows a notification for each one.
##
## Every achievement is checked when the event it depends on happens (a block found,
## a halving, a wallet change, a miner bought or a new epoch). Unlocked achievements persist across epochs.

## Emitted when an achievement is unlocked for the first time.
signal achievement_unlocked(id: String)

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "genesis", "name": "Genesis", "description": "Mine your first block."},
	{"id": "orphaned", "name": "Orphaned", "description": "Lose a block to the AI."},
	{"id": "halving", "name": "Tick Tock Next Block", "description": "Live through a halving."},
	{"id": "hodl_10", "name": "Stacker", "description": "Hold 10 BTC."},
	{"id": "hodl_100", "name": "Whale", "description": "Hold 100 BTC."},
	{"id": "first_miner", "name": "Home Miner", "description": "Buy your first miner."},
	{"id": "asic", "name": "Industrial", "description": "Buy an ASIC."},
	{"id": "hashrate_10", "name": "10% Attack", "description": "Own 10% of the network hashrate."},
	{"id": "new_epoch", "name": "Hard Fork", "description": "Start a new epoch."},
]

const SaveName: String = "achievements"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

var unlocked: Dictionary = {}


func _ready() -> void:
	add_to_group("PersistentNodes")
	BitcoinNetwork.block_found.connect(_on_block_found)
	BitcoinNetwork.halving_occurred.connect(func(_subsidy: float) -> void: unlock("halving"))
	BitcoinWallet.money_changed.connect(_on_money_changed)
	MiningFarm.miner_bought.connect(_on_miner_bought)
	MiningFarm.epoch_started.connect(func(_epoch: int, _points: int) -> void: unlock("new_epoch"))

## Unlocks the achievement with the given id and notifies the player. Does nothing if already unlocked.
func unlock(id: String) -> void:
	if unlocked.has(id): return
	var achievement: Dictionary = get_achievement(id)
	if achievement.is_empty(): return
	unlocked[id] = true
	achievement_unlocked.emit(id)
	NotificationManager.show_notification("Achievement unlocked: %s" % achievement.name, 3.0)

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func get_unlocked_count() -> int:
	return unlocked.size()

func get_achievement(id: String) -> Dictionary:
	for achievement in ACHIEVEMENTS:
		if achievement.id == id:
			return achievement
	return {}

func _on_block_found(block: BitcoinBlock) -> void:
	if block.miner == "Player" or block.miner == "player":
		unlock("genesis")
	elif block.miner == "AI":
		unlock("orphaned")
	_check_hashrate_share()

func _on_money_changed(_amount: float, currency: Constants.CurrencyType) -> void:
	if currency != Constants.CurrencyType.BITCOIN: return
	var balance: float = BitcoinWallet.get_bitcoin_balance()
	if balance >= 10.0: unlock("hodl_10")
	if balance >= 100.0: unlock("hodl_100")

func _on_miner_bought(miner_id: String, _owned: int) -> void:
	unlock("first_miner")
	if miner_id == "asic": unlock("asic")
	_check_hashrate_share()

func _check_hashrate_share() -> void:
	if MiningFarm.get_network_share() >= 0.1: unlock("hashrate_10")

func save_data() -> void:
	SaveSystem.set_var(SaveName, {"unlocked": unlocked.keys()})

func load_data() -> void:
	if !SaveSystem.has(SaveName): return
	var data: Dictionary = SaveSystem.get_var(SaveName)
	unlocked.clear()
	for id in data.get("unlocked", []):
		unlocked[id] = true
