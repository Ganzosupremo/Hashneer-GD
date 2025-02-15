extends Node2D

var inflation_rate: float = 0.02 # 2% inflation, which is a lie. It'll change later
var inflation_interval: int = 21 # Inflation will increase on every halving. Halving happens every 21 blocks
var total_inflation: float = 0.0 # The total in-game inflation since the beginning of times.
var fiat_currency_in_circulation: float = 0.0

func _ready() -> void:
	BitcoinNetwork.halving_occurred.connect(_on_halving_ocurred)

func _on_halving_ocurred(_new_subsidy: float) -> void:
	inflation_rate = randf_range(0.21, 0.69)
	var inflation_amount: float = fiat_currency_in_circulation * inflation_rate
	fiat_currency_in_circulation += inflation_amount
	total_inflation += inflation_rate
	#print("Inflation applied: ", inflation_amount)

func add_currency_in_circulation(new_coins) -> void:
	fiat_currency_in_circulation += new_coins

func get_currency_in_circulation() -> float:
	return fiat_currency_in_circulation

func get_total_inflation() -> float:
	return total_inflation