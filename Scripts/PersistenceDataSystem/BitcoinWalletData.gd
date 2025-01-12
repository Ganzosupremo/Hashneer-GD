class_name BitcoinWalletData extends Resource

@export var btc_holdings: float = 0.0
@export var fiat_holdings: float = 0.0
@export var bitcoin_price: float = 0.0

func _init(btc: float = 0.0, fiat: float = 0.0, price: float = 90_000.0) -> void:
	btc_holdings = btc
	fiat_holdings = fiat
	bitcoin_price = price
