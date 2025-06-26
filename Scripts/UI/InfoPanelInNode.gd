class_name SkillInfoPanelInNode extends Control

@export_category("Price Background Styles")
## Used when the player can afford the upgrade.
@export var can_afford_upgrade_style: StyleBoxTexture
## Used when the player cannot afford the upgrade.
@export var cannot_afford_upgrade_style: StyleBoxTexture
## Used when the upgrade has benn maxed out.
@export var max_ugraded_style: StyleBoxTexture

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
var currency: Constants.CurrencyType = Constants.CurrencyType.FIAT

func _ready() -> void:
	visible = false

func activate_panel(title: String, description: String, cost: int, currency_type: Constants.CurrencyType, is_maxed_out: bool = false) -> void:
        change_labels(title, description, cost, currency_type, is_maxed_out)
	visible = true
	animation_component.start_tween()

func deactivate_panel() -> void:
	price_background.remove_theme_stylebox_override("panel")
	animation_component.reset()
	visible = false

func _set_cost_icon(currency_type: Constants.CurrencyType) -> void:
        _set_currency(currency_type)
        if currency_type == Constants.CurrencyType.BITCOIN:
                btc_texture.visible = true
                fiat_texture.visible = false
        else:
                fiat_texture.visible = true
                btc_texture.visible = false

func change_labels(title: String, description: String, cost: int, currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT, is_maxed_out: bool = false) -> void:
        _set_currency(currency_type)
        skill_title.text = title
        if description.is_empty():
                skill_description.hide()
        else:
                skill_description.text = description

        _set_cost_icon(currency_type)
        update_cost_label(cost, currency_type, is_maxed_out)

func update_cost_label(cost: int, currency_type: Constants.CurrencyType = Constants.CurrencyType.FIAT, is_maxed_out: bool = false) -> void:
        _set_currency(currency_type)
        _change_price_background(currency_type, cost, is_maxed_out)
        skill_cost.text = "WELL DONE!" if is_maxed_out else Utils.format_currency(cost, true)

func _change_price_background(currency_type: Constants.CurrencyType, cost: float, is_maxed_out: bool = false) -> void:
        price_background.remove_theme_stylebox_override("panel")
        if is_maxed_out:
                price_background.add_theme_stylebox_override("panel", max_ugraded_style)
                skill_cost.label_settings = maxed_out_font
                return
        skill_cost.label_settings = normal_font
        if _get_currency_balance(currency_type) < cost:
                price_background.add_theme_stylebox_override("panel", cannot_afford_upgrade_style)
        else:
                price_background.add_theme_stylebox_override("panel", can_afford_upgrade_style)

func _set_currency(value: Constants.CurrencyType) -> void:
        currency = value

func _get_currency_balance(currency_type) -> float:
        return BitcoinWallet.get_bitcoin_balance() if currency_type == Constants.CurrencyType.BITCOIN else BitcoinWallet.get_fiat_balance()
