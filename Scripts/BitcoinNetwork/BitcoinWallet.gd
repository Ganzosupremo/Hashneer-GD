extends Node2D
class_name BWallet

signal money_changed(amount_changed: float, currency: Constants.CurrencyType) 

const API_REQUEST: String = "https://bitcoinexplorer.org/api/price"
@onready var request: HTTPRequest = $HTTPRequest

var bitcoin_balance: float = 0.0
var fiat_balance: float = 0.0
var bitcoin_price: float = 0.0
var static_bitcoin_price: float = 95_000.0

## In-game price of 1 BTC in fiat before any inflation or halving.
const BASE_BTC_PRICE_IN_FIAT: float = 20_000.0
## Fee the exchange keeps on every trade, in both directions.
const EXCHANGE_FEE: float = 0.05

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	BitcoinNetwork.coin_subsidy_issued.connect(on_reward_issued)

func on_reward_issued(reward: float) -> void:
	add_bitcoin(reward)

func on_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json != null:
			bitcoin_price = json["usd"].to_float()
		else:
			bitcoin_price = static_bitcoin_price
	else:
		bitcoin_price = static_bitcoin_price


func add_fiat(amount: float) -> void:
	if amount <= 0.0: return
	
	fiat_balance += amount
	money_changed.emit(fiat_balance, Constants.CurrencyType.FIAT)

func spend_fiat(amount_to_spend: float) -> bool:
	if amount_to_spend > fiat_balance:
		return false
	
	fiat_balance -= amount_to_spend
	money_changed.emit(fiat_balance, Constants.CurrencyType.FIAT)
	return true

func add_bitcoin(amount_to_add: float) -> void:
	if amount_to_add <= 0.0: return
	
	bitcoin_balance += amount_to_add
	money_changed.emit(bitcoin_balance, Constants.CurrencyType.BITCOIN)

func spend_bitcoin(amount_to_spend: float) -> bool:
	if amount_to_spend > bitcoin_balance:
		return false
	
	bitcoin_balance -= amount_to_spend
	BitcoinNetwork.add_coins_spent(amount_to_spend)
	money_changed.emit(bitcoin_balance, Constants.CurrencyType.BITCOIN)
	return true

## In-game price of 1 BTC in fiat. It rises with fiat inflation and with every halving,
## mirroring how Bitcoin prices in the skill tree drop (see [method Timechain.get_deflation_multiplier]).
func get_btc_price_in_fiat() -> float:
	return BASE_BTC_PRICE_IN_FIAT * FED.get_total_inflation() / BitcoinNetwork.get_deflation_multiplier()

## Returns how many BTC the given fiat buys on the exchange, after the fee.
func fiat_to_bitcoin(fiat_amount: float) -> float:
	return fiat_amount * (1.0 - EXCHANGE_FEE) / get_btc_price_in_fiat()

## Returns how much fiat the given BTC sells for on the exchange, after the fee.
func bitcoin_to_fiat(bitcoin_amount: float) -> float:
	return bitcoin_amount * get_btc_price_in_fiat() * (1.0 - EXCHANGE_FEE)

## Spends [param fiat_amount] on the exchange and adds the BTC bought to the wallet.
## Returns the BTC bought, or 0 if the balance is too low.
func buy_bitcoin(fiat_amount: float) -> float:
	if fiat_amount <= 0.0 or !spend_fiat(fiat_amount):
		return 0.0
	var btc: float = fiat_to_bitcoin(fiat_amount)
	add_bitcoin(btc)
	return btc

## Sells [param btc_amount] on the exchange and adds the fiat to the wallet.
## Returns the fiat received, or 0 if the balance is too low.
func sell_bitcoin(btc_amount: float) -> float:
	if btc_amount <= 0.0 or btc_amount > bitcoin_balance:
		return 0.0
	bitcoin_balance -= btc_amount
	money_changed.emit(bitcoin_balance, Constants.CurrencyType.BITCOIN)
	var fiat: float = bitcoin_to_fiat(btc_amount)
	add_fiat(fiat)
	return fiat

func get_fiat_balance() -> float:
	return fiat_balance

func get_bitcoin_balance() -> float:
	return bitcoin_balance

func save_data():
	SaveSystem.set_var(GameManager.WalletDataSaveName, _build_dictionary_to_save())

func _build_dictionary_to_save() -> Dictionary:
	return {
		"btc_holdings": bitcoin_balance,
		"fiat_holdings": fiat_balance,
		"btc_price": bitcoin_price,
		"economy_version": BitcoinNetwork.ECONOMY_VERSION
	}

func load_data():
	if !SaveSystem.has(GameManager.WalletDataSaveName): return
	
	var data: Dictionary = SaveSystem.get_var(GameManager.WalletDataSaveName)

	bitcoin_balance = data["btc_holdings"]
	fiat_balance = data["fiat_holdings"]
	bitcoin_price = data["btc_price"]
	if data.get("economy_version", 0) < BitcoinNetwork.ECONOMY_VERSION:
		bitcoin_balance *= BitcoinNetwork.LEGACY_BTC_SCALE

func _to_string() -> String:
	return "BTC holdings: %d\n" % bitcoin_balance + "Fiat Holdings: %d" % fiat_balance + "Current BTC price: %d" % bitcoin_price
