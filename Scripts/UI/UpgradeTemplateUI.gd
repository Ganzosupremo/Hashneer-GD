class_name UpgradeTemplateUI extends PanelContainer
## One Armory upgrade row: name, level bar, description, price and the buy button.
##
## The button is disabled when the upgrade is maxed or can't be afforded, and [member _status_label]
## says why. Hovering the button emits [signal preview_requested] so the Armory can show the stats
## the next level gives.

## Emitted when the mouse enters ([param is_showing] true) or leaves the buy button.
signal preview_requested(is_showing: bool)

const MAXED_COLOR: Color = Color(0.55, 1.0, 0.6)
const BLOCKED_COLOR: Color = Color(1.0, 0.5, 0.45)

@onready var _upgrade_name: Label = %UpgradeName
@onready var _upgrade_level: Label = %UpgradeLevel
@onready var _upgrade_description: Label = %UpgradeDescription
@onready var _fiat_price_label: Label = %FiatPriceLabel
@onready var _bitcoin_price_label: Label = %BitcoinPriceLabel
@onready var _level_bar: ProgressBar = get_node_or_null("%LevelBar")
@onready var _status_label: Label = get_node_or_null("%StatusLabel")
@onready var upgrade_button: Button = %UpgradeButton


func _ready() -> void:
	upgrade_button.mouse_entered.connect(func(): preview_requested.emit(true))
	upgrade_button.mouse_exited.connect(func(): preview_requested.emit(false))

## Fills the whole row.[br]
## [param blocked_reason] is shown under the price and disables the button (empty = can buy).
func set_upgrade_state(upgrade_name: String, description: String, level: int, max_level: int, fiat_cost: float, bitcoin_cost: float, blocked_reason: String = "") -> void:
	_upgrade_name.text = upgrade_name
	_upgrade_description.text = description
	_upgrade_level.text = "Lv.%d/%d" % [level, max_level]
	if _level_bar:
		_level_bar.max_value = max(max_level, 1)
		_level_bar.value = level

	var maxed: bool = level >= max_level
	_fiat_price_label.visible = !maxed
	_bitcoin_price_label.visible = !maxed and bitcoin_cost > 0.0
	_fiat_price_label.text = "$%s" % Utils.format_currency(fiat_cost, true)
	_bitcoin_price_label.text = "%s ₿" % Utils.format_btc(bitcoin_cost)

	upgrade_button.disabled = maxed or !blocked_reason.is_empty()
	upgrade_button.text = "MAX" if maxed else "Buy"
	if _status_label:
		_status_label.visible = maxed or !blocked_reason.is_empty()
		_status_label.text = "Maxed out" if maxed else blocked_reason
		_status_label.modulate = MAXED_COLOR if maxed else BLOCKED_COLOR

## Kept for older callers: fills the row without a max level or a blocked state.
func set_upgrade_details(upgrade_name: String, level: int, description: String, fiat_cost: float, bitcoin_cost: float) -> void:
	set_upgrade_state(upgrade_name, description, level, max(level + 1, 1), fiat_cost, bitcoin_cost)

func update_upgrade_details(level: int, fiat_price: float, bitcoin_price: float) -> void:
	_fiat_price_label.text = "$ %s" % Utils.format_currency(fiat_price, true)
	_bitcoin_price_label.text = "%s ₿" % Utils.format_btc(bitcoin_price)
	_upgrade_level.text = "Lv.%d" % level
