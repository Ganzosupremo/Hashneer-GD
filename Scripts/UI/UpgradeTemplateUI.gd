class_name UpgradeTemplateUI extends PanelContainer

@onready var _upgrade_name: Label = %UpgradeName
@onready var _upgrade_level: Label = %UpgradeLevel
@onready var _upgrade_description: Label = %UpgradeDescription
@onready var _fiat_price_label: Label = %FiatPriceLabel
@onready var _bitcoin_price_label: Label = %BitcoinPriceLabel


func _on_upgrade_button_pressed() -> void:
	pass # Replace with function body.

func update_upgrade_details(level: int, fiat_price: float, bitcoin_price: float) -> void:
	_fiat_price_label.text = "$%d" % Utils.format_currency(fiat_price, true)
	_bitcoin_price_label.text = "%d₿" % Utils.format_currency(bitcoin_price, true)
	_upgrade_level.text = "Lv.%d" % level

func set_upgrade_details(upgrade_name: String, level: int, description: String, fiat_price: int, bitcoin_price: int) -> void:
	_upgrade_name.text = upgrade_name
	_upgrade_level.text = "Lv.%d" % level
	_upgrade_description.text = description
	_fiat_price_label.text = "$%d" % Utils.format_currency(fiat_price, true)
	_bitcoin_price_label.text = "%d₿" % Utils.format_currency(bitcoin_price, true)
