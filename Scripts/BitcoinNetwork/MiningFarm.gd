extends Node
## MiningFarm handles the idle part of the game: the player's mining hardware and the epochs (prestige).
##
## Miners are bought with fiat and add hashrate. Hashrate earns transaction fees in Bitcoin over time,
## even while the game is closed. Fees are paid by the network, so they never add to the coin supply
## tracked by the [Timechain]. The share of the fees depends on the player's share of the network hashrate,
## which grows with every block mined.[br]
## When the whole chain has been mined the player can start a new epoch: everything resets except the
## HODL points earned, which permanently boost hashrate and fiat drops.

## Emitted when the player buys a miner.
signal miner_bought(miner_id: String, owned: int)
## Emitted when fees are paid into the wallet.
signal fees_earned(btc: float)
## Emitted when a new epoch starts after a reset.
signal epoch_started(epoch: int, hodl_points: int)

## The mining hardware the player can buy. Hashrate in TH/s, cost in fiat before inflation.
const MINERS: Array[Dictionary] = [
	{"id": "cpu", "name": "CPU Miner", "hashrate": 1.0, "base_cost": 5_000.0},
	{"id": "gpu", "name": "GPU Rig", "hashrate": 8.0, "base_cost": 60_000.0},
	{"id": "asic", "name": "ASIC", "hashrate": 64.0, "base_cost": 750_000.0},
]
## Every miner of the same type costs this much more than the previous one.
const MINER_COST_MULTIPLIER: float = 1.15

## Hashrate of the rest of the network before the first block, in TH/s.
const BASE_NETWORK_HASHRATE: float = 50.0
## The network hashrate grows by this factor with every block mined.
const NETWORK_HASHRATE_GROWTH: float = 1.6
## Total fees paid by the network per hour before the first halving.
## Fees grow after every halving as they replace the block subsidy.
const FEE_POOL_BTC_PER_HOUR: float = 6.0
const FEE_POOL_GROWTH_PER_HALVING: float = 0.5
## Offline earnings stop after this many hours away.
const MAX_OFFLINE_HOURS: float = 8.0
## The AI timer gets up to this much longer, scaled by the player's share of the network.
const MAX_AI_TIMER_BONUS: float = 2.0

## Permanent bonus per HODL point.
const HASHRATE_BONUS_PER_POINT: float = 0.10
const FIAT_DROP_BONUS_PER_POINT: float = 0.05

const SaveName: String = "mining_farm"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

## Amount of miners owned, by miner id.
var owned: Dictionary = {"cpu": 0, "gpu": 0, "asic": 0}
## Current epoch, starts at 1.
var epoch: int = 1
## HODL points earned in previous epochs.
var hodl_points: int = 0

var _pending_fees: float = 0.0
var _payout_timer: float = 0.0
var _loaded: bool = false


func _ready() -> void:
	add_to_group("PersistentNodes")

func _process(delta: float) -> void:
	_pending_fees += get_fees_per_second() * delta
	_payout_timer += delta
	if _payout_timer < 1.0: return
	_payout_timer = 0.0
	if _pending_fees <= 0.0: return
	BitcoinWallet.add_bitcoin(_pending_fees)
	fees_earned.emit(_pending_fees)
	_pending_fees = 0.0

#region Miners

## Returns the fiat cost of the next miner of the given type, adjusted by inflation.
func get_miner_cost(miner_id: String) -> float:
	var miner: Dictionary = _get_miner(miner_id)
	return miner.base_cost * pow(MINER_COST_MULTIPLIER, owned.get(miner_id, 0)) * FED.get_total_inflation()

## Buys one miner of the given type with fiat. Returns [code]true[/code] on success.
func buy_miner(miner_id: String) -> bool:
	if _get_miner(miner_id).is_empty(): return false
	if !BitcoinWallet.spend_fiat(get_miner_cost(miner_id)): return false
	owned[miner_id] = owned.get(miner_id, 0) + 1
	miner_bought.emit(miner_id, owned[miner_id])
	return true

func get_owned(miner_id: String) -> int:
	return owned.get(miner_id, 0)

func _get_miner(miner_id: String) -> Dictionary:
	for miner in MINERS:
		if miner.id == miner_id:
			return miner
	return {}

#endregion

#region Hashrate and fees

## The player's hashrate in TH/s, including the HODL points bonus.
func get_hashrate() -> float:
	var total: float = 0.0
	for miner in MINERS:
		total += miner.hashrate * owned.get(miner.id, 0)
	return total * (1.0 + HASHRATE_BONUS_PER_POINT * hodl_points)

## The hashrate of the rest of the network (other miners and the AI) in TH/s.
func get_network_hashrate() -> float:
	return BASE_NETWORK_HASHRATE * pow(NETWORK_HASHRATE_GROWTH, BitcoinNetwork.get_blockheight())

## The player's share of the total hashrate, from 0 to 1.
func get_network_share() -> float:
	var hashrate: float = get_hashrate()
	if hashrate <= 0.0: return 0.0
	return hashrate / (hashrate + get_network_hashrate())

## Bitcoin earned in fees per second.
func get_fees_per_second() -> float:
	var pool: float = FEE_POOL_BTC_PER_HOUR * (1.0 + FEE_POOL_GROWTH_PER_HALVING * BitcoinNetwork.get_halvings_count())
	return pool / 3600.0 * get_network_share()

## How much longer the AI takes to mine a block thanks to the player's hashrate.
func get_ai_timer_multiplier() -> float:
	return 1.0 + MAX_AI_TIMER_BONUS * get_network_share()

## Multiplier applied to fiat drops by the HODL points.
func get_fiat_drop_multiplier() -> float:
	return 1.0 + FIAT_DROP_BONUS_PER_POINT * hodl_points

#endregion

#region Epochs

## A new epoch can start once the block of the last level has been mined, by anyone.
func can_start_new_epoch() -> bool:
	return BitcoinNetwork.is_level_mined(GameManager.game_levels.size() - 1)

## HODL points the player gets by starting a new epoch now. Rewards the Bitcoin held, not spent.
func get_points_for_new_epoch() -> int:
	return max(1, floori(sqrt(BitcoinWallet.get_bitcoin_balance())))

## Resets the farm for a new epoch and adds the HODL points earned.
## The rest of the reset is orchestrated by [method SkillTreeManager.start_new_epoch].
func start_new_epoch() -> int:
	var points: int = get_points_for_new_epoch()
	hodl_points += points
	epoch += 1
	for id in owned.keys():
		owned[id] = 0
	_pending_fees = 0.0
	epoch_started.emit(epoch, hodl_points)
	return points

#endregion

#region Persistence

func save_data() -> void:
	SaveSystem.set_var(SaveName, {
		"owned": owned,
		"epoch": epoch,
		"hodl_points": hodl_points,
		"last_seen": Time.get_unix_time_from_system(),
	})

func load_data() -> void:
	if _loaded: return
	_loaded = true
	if !SaveSystem.has(SaveName): return

	var data: Dictionary = SaveSystem.get_var(SaveName)
	var saved_owned: Dictionary = data.get("owned", {})
	for id in owned.keys():
		owned[id] = int(saved_owned.get(id, 0))
	epoch = int(data.get("epoch", 1))
	hodl_points = int(data.get("hodl_points", 0))
	# Deferred so the wallet has loaded its own data before the fees are added
	_pay_offline_fees.call_deferred(data.get("last_seen", 0.0))

func _pay_offline_fees(last_seen: float) -> void:
	if last_seen <= 0.0: return
	var seconds_away: float = clampf(Time.get_unix_time_from_system() - last_seen, 0.0, MAX_OFFLINE_HOURS * 3600.0)
	var fees: float = get_fees_per_second() * seconds_away
	if fees <= 0.0: return
	BitcoinWallet.add_bitcoin(fees)
	fees_earned.emit(fees)
	NotificationManager.show_notification("While you were away your miners earned %s BTC in fees" % Utils.format_btc(fees), 4.0)

#endregion
