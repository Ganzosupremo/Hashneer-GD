extends Node2D
class_name Wallet

signal money_printer_goes(fiat_amount: float)

const API_REQUEST: String = "https://bitcoinexplorer.org/api/price"

@onready var request: HTTPRequest = $HTTPRequest

var current_bitcoin: float = 0.0
var current_fiat: float = 0.0
var bitcoin_price: float = 0.0
var static_bitcoin_price: float = 35000.0

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	BitcoinNetwork.reward_issued.connect(on_reward_issued)
	request.request_completed.connect(on_request_completed)
	request.request(API_REQUEST)
	
	await request.request_completed
	
	var timer: Timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(on_timeout)
	timer.one_shot = false
	timer.wait_time = 600.0

func on_reward_issued(reward: float) -> void:
	current_bitcoin += reward

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


func add_fiat(amount: float):
	if amount <= 0.0:
		current_fiat += 0.0
		return
	
	current_fiat += amount	
	emit_signal("money_printer_goes", current_fiat)

## exchanges the fiat currency to Bitcoin
func fiat_to_bitcoin(fiat_amount: float) -> float:
	return fiat_amount / bitcoin_price

## exchanges Bitcoin to fiat currency
func bitcoin_to_fiat(bitcoin_amount: float) -> float:
	return bitcoin_amount * bitcoin_price

func save() -> Dictionary:
	return {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"BTC Holdings": current_bitcoin,
		"Fiat Holdings": current_fiat,
		"Last BTC price": bitcoin_price,
	}

func save_data(data: GameData):
	var wallet_data = GameData.BitcoinWalletData.new()
	wallet_data.btc_holdings = self.current_bitcoin
	wallet_data.fiat_holdings = self.current_fiat
	wallet_data.bitcoin_price = self.bitcoin_price
	data.data["bitcoin_wallet_data"] = wallet_data

func load_data(data: GameData):
	var wallet_data = data.data["bitcoin_wallet_data"]
	
	self.current_bitcoin = wallet_data.btc_holdings
	self.current_fiat = wallet_data.fiat_holdings
	self.bitcoin_price = wallet_data.bitcoin_price
