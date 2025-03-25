extends Node2D

var inflation_rate: float = 0.02 # 2% inflation, which is the lowest it can go.
var inflation_interval: int = 2 # Inflation will increase on every halving. Halving happens every 21 blocks
var total_inflation: float = 0.0 # The total in-game inflation since the beginning of times.
var fiat_currency_in_circulation: float = 0.0


const FEDSaveName: String = "the_fed"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]


func _ready() -> void:
	BitcoinNetwork.halving_occurred.connect(_on_halving_ocurred)

func _on_halving_ocurred(_new_subsidy: float) -> void:
	inflation_rate = randf_range(0.02, 0.69)
	var inflation_amount: float = fiat_currency_in_circulation * inflation_rate
	fiat_currency_in_circulation += inflation_amount
	total_inflation += inflation_rate

func add_currency_in_circulation(new_coins) -> void:
	fiat_currency_in_circulation += new_coins

func get_currency_in_circulation() -> float:
	return fiat_currency_in_circulation


func authorize_transaction(amount: float) -> bool:
	fiat_currency_in_circulation += amount
	var prob: float = _probability_from_amount(amount)
	if randf() < prob:
		print("Transaction denied")
		return false
	
	BitcoinWallet.add_fiat(amount)
	return true

func get_total_inflation() -> float:
	return total_inflation

func get_fiat_subsidy() -> float:
	var subsidy: float = randf_range(250.0, 2500.0) * GameManager.get_builder_args().fiat_drop_rate_factor
	fiat_currency_in_circulation += subsidy
	return subsidy

func _probability_from_amount(amount: float) -> float:
	var log_amount = log(amount) / log(10)
	log_amount = clamp(log_amount, 4.0, 7.0)
	return (log_amount - 4.0) / 4.0


func save_data():
	SaveSystem.set_var(FEDSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	return {
		"total_inflation": total_inflation,
		"fiat_currency_in_circulation": fiat_currency_in_circulation
	}

func load_data():
	if !SaveSystem.has(FEDSaveName): return

	var data: Dictionary = SaveSystem.get_var(FEDSaveName)
	total_inflation = data["total_inflation"]
	fiat_currency_in_circulation = data["fiat_currency_in_circulation"]
