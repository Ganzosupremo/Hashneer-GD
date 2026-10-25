extends Node2D

## Emitted every time a block is found and the FED prints more money.
signal inflation_applied(rate: float, total: float)

## Inflation applied on every block before the first halving.
const BASE_INFLATION_RATE: float = 0.04
## The FED prints a bit faster after every halving.
const INFLATION_INCREASE_PER_HALVING: float = 0.02
## Fiat drops grow with the square root of the total inflation, so earnings lag behind prices
## and holding fiat always loses purchasing power.
const WAGE_INFLATION_EXPONENT: float = 0.5

## The inflation rate applied on the last block.
var inflation_rate: float = BASE_INFLATION_RATE
var total_inflation: float = 1.0 # Accumulated inflation multiplier since the beginning of time.
var fiat_currency_in_circulation: float = 0.0


const FEDSaveName: String = "the_fed"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]


func _ready() -> void:
	BitcoinNetwork.block_found.connect(_on_block_found)

func _on_block_found(_block: BitcoinBlock) -> void:
	inflation_rate = get_current_inflation_rate()
	var inflation_factor: float = 1.0 + inflation_rate
	fiat_currency_in_circulation *= inflation_factor
	total_inflation *= inflation_factor
	inflation_applied.emit(inflation_rate, total_inflation)

## The inflation rate the FED applies on the next block, it grows with every halving.
func get_current_inflation_rate() -> float:
	return BASE_INFLATION_RATE + INFLATION_INCREASE_PER_HALVING * BitcoinNetwork.get_halvings_count()

func add_currency_in_circulation(new_coins) -> void:
	fiat_currency_in_circulation += new_coins

func get_currency_in_circulation() -> float:
	return fiat_currency_in_circulation

## Tries to add the amount to the wallet, theres a chance it will be denied
func authorize_transaction(amount: float) -> bool:
	var prob: float = _probability_from_amount(amount)
	if randf() < prob:
		return false
	
	BitcoinWallet.add_fiat(amount)
	return true

## Resets prices for a new epoch, see [method MiningFarm.start_new_epoch].
func reset_for_new_epoch() -> void:
	inflation_rate = BASE_INFLATION_RATE
	total_inflation = 1.0
	fiat_currency_in_circulation = 0.0

func get_total_inflation() -> float:
	return total_inflation

func get_fiat_subsidy() -> float:
	var subsidy: float = randf_range(250.0, 2500.0)
	if GameManager.get_level_args() != null:
		subsidy *= GameManager.get_level_args().fiat_drop_rate_factor
	subsidy *= pow(total_inflation, WAGE_INFLATION_EXPONENT)
	subsidy *= MiningFarm.get_fiat_drop_multiplier()
	fiat_currency_in_circulation += subsidy
	return subsidy

func _probability_from_amount(amount: float) -> float:
	var log_amount = log(amount) / log(10)
	log_amount = clamp(log_amount, 5.0, 7.0)
	return (log_amount - 5.0) / 5.0


func save_data():
	SaveSystem.set_var(FEDSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	return {
		"total_inflation": total_inflation,
		"inflation_rate": inflation_rate,
		"fiat_currency_in_circulation": fiat_currency_in_circulation
	}

func load_data():
	if !SaveSystem.has(FEDSaveName): return

	var data: Dictionary = SaveSystem.get_var(FEDSaveName)
	total_inflation = data.get("total_inflation", 1.0)
	inflation_rate = data.get("inflation_rate", BASE_INFLATION_RATE)
	fiat_currency_in_circulation = data.get("fiat_currency_in_circulation", 0.0)
