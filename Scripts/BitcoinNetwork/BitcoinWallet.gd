extends Node2D
class_name BWallet

signal money_changed(amount_changed: float, is_bitcoin: bool) 

const API_REQUEST: String = "https://bitcoinexplorer.org/api/price"
@onready var request: HTTPRequest = $HTTPRequest

var bitcoin_balance: float = 0.0
var fiat_balance: float = 0.0
var bitcoin_price: float = 0.0
var static_bitcoin_price: float = 95_000.0
var data: BitcoinWalletData

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	BitcoinNetwork.reward_issued.connect(on_reward_issued)
	request.request_completed.connect(on_request_completed)
	request.request(API_REQUEST)
	data = BitcoinWalletData.new(bitcoin_balance, fiat_balance, bitcoin_price)
	await request.request_completed
	
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(on_timeout)
	timer.one_shot = false
	timer.wait_time = 600.0

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

func on_timeout():
	request.request(API_REQUEST)


func add_fiat(amount: float) -> void:
	if amount <= 0.0: return
	
	fiat_balance += amount
	#emit_signal("money_printer_goes", fiat_balance)
	emit_signal("money_changed", fiat_balance, false)

func spend_fiat(amount_to_spend: float) -> bool:
	if amount_to_spend > fiat_balance:
		return false
	
	fiat_balance -= amount_to_spend
	emit_signal("money_changed", fiat_balance, false)
	return true

func add_bitcoin(amount_to_add: float) -> void:
	if amount_to_add <= 0.0: return
	
	bitcoin_balance += amount_to_add
	emit_signal("money_changed", bitcoin_balance, true)

func spend_bitcoin(amount_to_spend: float) -> bool:
	if amount_to_spend > bitcoin_balance:
		return false
	
	bitcoin_balance -= amount_to_spend
	emit_signal("money_changed", bitcoin_balance, true)
	return true

## exchanges the fiat currency to Bitcoin
func fiat_to_bitcoin(fiat_amount: float) -> float:
	return fiat_amount / bitcoin_price

## exchanges Bitcoin to fiat currency
func bitcoin_to_fiat(bitcoin_amount: float) -> float:
	return bitcoin_amount * bitcoin_price

func get_fiat_balance() -> float:
	return fiat_balance

func get_bitcoin_balance() -> float:
	return bitcoin_balance

func save_data():
	var wallet_data: BitcoinWalletData = BitcoinWalletData.new(bitcoin_balance, fiat_balance, bitcoin_price)
	var error = ResourceSaver.save(wallet_data, GameManager.WalletDataSaveName)
	if error != OK:
		print_debug("not saved: ", error)
	else:
		print_debug("saved: ", wallet_data)
	# GameManager.set_resource_to_game_data_dic(wallet_data, GameManager.ResourceDataType.WalletData)

func load_data():
	
	var wallet_data: BitcoinWalletData = ResourceLoader.load(GameManager.WalletDataSaveName, "BitcoinWalletData", ResourceLoader.CACHE_MODE_REPLACE)   #GameManager.get_resource_from_game_data_dic(GameManager.ResourceDataType.WalletData)
	if wallet_data == null: 
		print_debug("not loaded: ", wallet_data)
		return
	print_debug("loaded: ", wallet_data)
	data = wallet_data.duplicate(true)
	self.bitcoin_balance = data.btc_holdings
	self.fiat_balance = data.fiat_holdings
	self.bitcoin_price = data.bitcoin_price

func _to_string() -> String:
	return "BTC holdings: %d\n" % bitcoin_balance + "Fiat Holdings: %d" % fiat_balance + "Current BTC price: %d" % bitcoin_price
