class_name UpgradeTemplateUI extends PanelContainer

@onready var _upgrade_name: Label = %UpgradeName
@onready var _upgrade_level: Label = %UpgradeLevel
@onready var _upgrade_description: Label = %UpgradeDescription
@onready var _fiat_price_label: Label = %FiatPriceLabel
@onready var _bitcoin_price_label: Label = %BitcoinPriceLabel
@onready var upgrade_button: Button = %UpgradeButton


func _on_upgrade_button_pressed() -> void:
	pass # Replace with function body.

func update_upgrade_details(level: int, fiat_price: float, bitcoin_price: float) -> void:
	_fiat_price_label.text = "$ %s" % Utils.format_currency(fiat_price, true)
	_bitcoin_price_label.text = "%s ₿" % Utils.format_currency(bitcoin_price, true)
	_upgrade_level.text = "Lv.%d" % level

func set_upgrade_details(upgrade_name: String, level: int, description: String, fiat_cost: float, bitcoin_cost: float) -> void:
	_upgrade_name.text = upgrade_name
	_upgrade_level.text = "Lv.%d" % level
	_upgrade_description.text = description
	_fiat_price_label.text = "$%s" % Utils.format_currency(fiat_cost, true)
	
	if bitcoin_cost > 0.0:
		_bitcoin_price_label.visible = true
		_bitcoin_price_label.text = "%s ₿" % Utils.format_currency(bitcoin_cost, true)
	else:
		_bitcoin_price_label.visible = false
