class_name CurrencyUI extends Control

signal currency_changed(currency: Constants.CurrencyType)

@export var main_event_bus: MainEventBus

@onready var btc_label: Label = %BitcoinLabel
@onready var fiat_label: Label = %FiatLabel
@onready var use_btc_button: CheckButton = %UseBTCButton

var skill_tree: SkillTreeManager = null

func _ready() -> void:
	skill_tree = get_tree().get_first_node_in_group("SkillsTree")
	BitcoinWallet.money_changed.connect(_on_money_changed)
	_set_textes()

func _set_textes() -> void:
	var btc_balance: float = BitcoinWallet.get_bitcoin_balance()
	var fiat_balance: float = BitcoinWallet.get_fiat_balance()

	var btc_text: String = Utils.format_currency(int(btc_balance), true)
	var fiat_text: String = Utils.format_currency(int(fiat_balance), true)

	btc_label.text = btc_text
	fiat_label.text = fiat_text

func hide_ui() -> void:
	hide()

func show_ui() -> void:
	show()

func _on_money_changed(amount: float, is_bitcoin: bool = false) -> void:
	var amount_text: String = ""
	
	if !is_bitcoin:
		amount_text = Utils.format_currency(int(amount), true)
		fiat_label.text = amount_text
	else:
		amount_text = Utils.format_currency(int(amount), true)
		btc_label.text = amount_text

func _on_use_btc_button_toggled(toggled_on: bool) -> void:
        var currency := Constants.CurrencyType.BITCOIN if toggled_on else Constants.CurrencyType.FIAT
        main_event_bus.currency_changed.emit(currency)
        currency_changed.emit(currency)
