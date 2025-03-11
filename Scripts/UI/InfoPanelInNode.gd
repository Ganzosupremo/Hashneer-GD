class_name SkillInfoPanelInNode extends Control

@export_category("Price Background Styles")
## Used when the player can afford the upgrade.
@export var can_afford_upgrade_style: StyleBoxFlat
## Used when the player cannot afford the upgrade.
@export var cannot_afford_upgrade_style: StyleBoxFlat
## Used when the upgrade has benn maxed out.
@export var max_ugraded_style: StyleBoxFlat

@export_group("Label Settings")
@export var normal_font: LabelSettings
@export var maxed_out_font: LabelSettings


@onready var skill_title: Label = $PanelContainer/VBoxContainer/SkillTitle
@onready var skill_description: Label = $PanelContainer/VBoxContainer/SkillDescription
@onready var skill_cost: Label = $PanelContainer/VBoxContainer/PriceBackground/HBoxContainer/SkillCost
@onready var fiat_texture: TextureRect = $PanelContainer/VBoxContainer/PriceBackground/HBoxContainer/FiatTexture
@onready var btc_texture: TextureRect = $PanelContainer/VBoxContainer/PriceBackground/HBoxContainer/BTCTexture
@onready var animation_component: AnimationComponentUI = $AnimationComponent
@onready var price_background: PanelContainer = $PanelContainer/VBoxContainer/PriceBackground

## There's no need for this bool, but save the state just in case
var use_btc_icon: bool = false

func _ready() -> void:
	visible = false

func activate_panel(title: String, description: String, cost: int, use_bitcoin: bool, is_maxed_out: bool = false) -> void:
	change_labels(title, description, cost, use_bitcoin, is_maxed_out)
	visible = true
	#animation_component.start_tween()

func deactivate_panel() -> void:
	price_background.remove_theme_stylebox_override("panel")
	visible = false

func _set_cost_icon(use_bitcoin: bool) -> void:
	_set_use_btc_icon(use_bitcoin)
	if use_bitcoin:
		btc_texture.visible = true
		fiat_texture.visible = false
	else:
		fiat_texture.visible = true
		btc_texture.visible = false

func change_labels(title: String, description: String, cost: int, use_bitcoin: bool = false, is_maxed_out: bool = false) -> void:
	_set_use_btc_icon(use_bitcoin)
	skill_title.text = title
	if description.is_empty():
		skill_description.hide()
	else:
		skill_description.text = description
	
	_set_cost_icon(use_bitcoin)
	update_cost_label(cost, use_bitcoin, is_maxed_out)

func update_cost_label(cost: int, use_bitcoin: bool = false, is_maxed_out: bool = false) -> void:
	_set_use_btc_icon(use_bitcoin)
	_change_price_background(use_bitcoin, cost, is_maxed_out)
	skill_cost.text = "WELL DONE!" if is_maxed_out else Utils.format_currency(cost, true)

func _change_price_background(use_bitcoin: bool, cost: float, is_maxed_out: bool = false) -> void:
	price_background.remove_theme_stylebox_override("panel")
	if is_maxed_out:
		price_background.add_theme_stylebox_override("panel", max_ugraded_style)
		skill_cost.label_settings = maxed_out_font
		return
	skill_cost.label_settings = normal_font
	if _get_currency_balance(use_bitcoin) < cost:
		price_background.add_theme_stylebox_override("panel", cannot_afford_upgrade_style)
	else:
		price_background.add_theme_stylebox_override("panel", can_afford_upgrade_style)

func _set_use_btc_icon(value: bool) -> void:
	use_btc_icon = value

func _get_currency_balance(use_bitcoin) -> float:
	return BitcoinWallet.get_bitcoin_balance() if use_bitcoin else BitcoinWallet.get_fiat_balance()
