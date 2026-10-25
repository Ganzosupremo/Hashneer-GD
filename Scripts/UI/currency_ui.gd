class_name CurrencyUI extends Control

signal currency_changed(currency: Constants.CurrencyType)

@export var main_event_bus: MainEventBus

@onready var btc_label: Label = %BitcoinLabel
@onready var fiat_label: Label = %FiatLabel
@onready var use_btc_button: CheckButton = %UseBTCButton
@onready var _btc_price_label: Label = %BtcPriceLabel
@onready var _inflation_label: Label = %InflationLabel
@onready var _halving_label: Label = %HalvingLabel
@onready var _buy_button: Button = %BuyButton
@onready var _sell_button: Button = %SellButton

## Share of the balance traded each time an exchange button is pressed.
const EXCHANGE_TRADE_SHARE: float = 0.25

var skill_tree: SkillTreeManager = null

func _ready() -> void:
	skill_tree = get_tree().get_first_node_in_group("SkillsTree")
	BitcoinWallet.money_changed.connect(_on_money_changed)
	FED.inflation_applied.connect(_on_inflation_applied)
	_buy_button.tooltip_text = "Spend %d%% of your fiat on Bitcoin (%d%% fee)" % [EXCHANGE_TRADE_SHARE * 100, BitcoinWallet.EXCHANGE_FEE * 100]
	_sell_button.tooltip_text = "Sell %d%% of your Bitcoin for fiat (%d%% fee)" % [EXCHANGE_TRADE_SHARE * 100, BitcoinWallet.EXCHANGE_FEE * 100]
	_set_textes()

func _exit_tree() -> void:
	FED.inflation_applied.disconnect(_on_inflation_applied)

func _update_market_labels() -> void:
	_btc_price_label.text = "1 ₿ = $%s" % Utils.format_currency(BitcoinWallet.get_btc_price_in_fiat(), true)
	_inflation_label.text = "Inflation: +%d%%/block (x%.2f)" % [roundi(FED.get_current_inflation_rate() * 100.0), FED.get_total_inflation()]
	_halving_label.text = "Next halving in %d blocks" % BitcoinNetwork.get_blocks_until_next_halving()

func _on_buy_btc_pressed() -> void:
	if BitcoinWallet.buy_bitcoin(BitcoinWallet.get_fiat_balance() * EXCHANGE_TRADE_SHARE) > 0.0:
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)

func _on_sell_btc_pressed() -> void:
	if BitcoinWallet.sell_bitcoin(BitcoinWallet.get_bitcoin_balance() * EXCHANGE_TRADE_SHARE) > 0.0:
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)

func _on_inflation_applied(_rate: float, _total: float) -> void:
	_update_market_labels()

func _set_textes() -> void:
	var btc_balance: float = BitcoinWallet.get_bitcoin_balance()
	var fiat_balance: float = BitcoinWallet.get_fiat_balance()

	var btc_text: String = Utils.format_btc(btc_balance)
	var fiat_text: String = Utils.format_currency(int(fiat_balance), true)

	btc_label.text = btc_text
	fiat_label.text = fiat_text
	_update_market_labels()

func hide_ui() -> void:
	hide()

func show_ui() -> void:
	show()

func _on_money_changed(amount: float, currency: Constants.CurrencyType = Constants.CurrencyType.FIAT) -> void:
	var amount_text: String = ""
	match currency:
		Constants.CurrencyType.FIAT:
			amount_text = Utils.format_currency(int(amount), true)
			fiat_label.text = amount_text
		Constants.CurrencyType.BITCOIN:
			amount_text = Utils.format_btc(amount)
			btc_label.text = amount_text

func _on_use_btc_button_toggled(toggled_on: bool) -> void:
		var currency: Constants.CurrencyType = Constants.CurrencyType.BITCOIN if toggled_on else Constants.CurrencyType.FIAT
		main_event_bus.emit_currency_changed(currency)
		currency_changed.emit(currency)
