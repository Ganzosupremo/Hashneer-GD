extends Control

@onready var btc_label: Label = %BTCLabel
@onready var fiat_label: Label = %FiatLabel

func _ready() -> void:
	btc_label.text = "BTC Gained: 0 Sats"
	fiat_label.text = "Fiat: 0"
	BitcoinNetwork.reward_issued.connect(on_reward_issued)
	BitcoinWallet.money_printer_goes.connect(on_money_printed)

func on_reward_issued(reward: float) -> void:
	btc_label.text = "BTC Gained: " + str(reward) + " Sats"

func on_money_printed(amount_printed: float):
	fiat_label.text = "Fiat: " + str(amount_printed)
