extends Control

@onready var btc_label: Label = %BitcoinLabel
@onready var fiat_label: Label = %FiatLabel

var info_window

func _ready() -> void:
	info_window = get_node_or_null("../SkillInfoWindow")
	_set_textes()
#	BitcoinNetwork.reward_issued.connect(on_reward_issued)
#	BitcoinWallet.money_printer_goes.connect(on_money_printed)
	BitcoinWallet.money_changed.connect(on_money_changed)
	
#	if info_window != null:
#		info_window.opened.connect(hide_ui)
#		info_window.closed.connect(show_ui)

func _set_textes() -> void:
	btc_label.text = "%.2f" % BitcoinWallet.get_bitcoin_balance()
	fiat_label.text = "%.2f" % BitcoinWallet.get_fiat_balance()

func hide_ui() -> void:
	hide()

func show_ui() -> void:
	show()

func on_reward_issued(_reward: float) -> void:
	var total = BitcoinWallet.get_bitcoin_balance()
	btc_label.text = "%.2f" % total

func on_money_changed(amount_changed, is_bitcoin: bool) -> void:
	if !is_bitcoin:
		fiat_label.text = "%.2f" % amount_changed
	else:
		btc_label.text = "%.2f" % amount_changed

func on_money_printed(stock_amount: float):
	fiat_label.text = "%.2f" % stock_amount
