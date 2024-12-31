extends Control

@onready var btc_label: Label = %BitcoinLabel
@onready var fiat_label: Label = %FiatLabel

func _ready() -> void:
	BitcoinNetwork.bitcoin_wallet.money_changed.connect(on_money_changed)
	_set_textes()

func _set_textes() -> void:
	btc_label.text = "%.2f" % BitcoinNetwork.bitcoin_wallet.get_bitcoin_balance()
	fiat_label.text = "%.2f" % BitcoinNetwork.bitcoin_wallet.get_fiat_balance()

func hide_ui() -> void:
	hide()

func show_ui() -> void:
	show()

func on_money_changed(amount_changed, is_bitcoin: bool = false) -> void:
	if !is_bitcoin:
		fiat_label.text = "%.2f" % amount_changed
	else:
		btc_label.text = "%.2f" % amount_changed
