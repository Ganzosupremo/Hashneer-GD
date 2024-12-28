class_name SkillInfoPanelInNode extends Control

@export var use_btc_icon: bool = true

@export_category("Price Background Styles")
## Used when the player can afford the upgrade.
@export var can_afford_upgrade_style: StyleBoxFlat
## Used when the player cannot afford the upgrade.
@export var cannot_afford_upgrade_style: StyleBoxFlat
## Used when the upgrade has benn maxed out.
@export var max_ugraded_style: StyleBoxFlat


@onready var skill_title: Label = $PanelContainer/VBoxContainer/SkillTitle
@onready var skill_description: RichTextLabel = $PanelContainer/VBoxContainer/SkillDescription
@onready var skill_cost: Label = $PanelContainer/VBoxContainer/PriceBackground/HBoxContainer/SkillCost
@onready var fiat_texture: TextureRect = $PanelContainer/VBoxContainer/PriceBackground/HBoxContainer/FiatTexture
@onready var btc_texture: TextureRect = $PanelContainer/VBoxContainer/PriceBackground/HBoxContainer/BTCTexture
@onready var animation_component: AnimationComponentUI = $AnimationComponent
@onready var price_background: PanelContainer = $PanelContainer/VBoxContainer/PriceBackground

var current_currency: float = 0.0

func _ready() -> void:
	visible = false

func activate_panel(title: String, description: String, cost: float, use_bitcoin: bool, is_maxed_out: bool = false) -> void:
	change_labels(title, description, cost, is_maxed_out)
	_set_cost_icon(use_bitcoin)
	visible = true
	animation_component.start_tween()

func deactivate_panel() -> void:
	visible = false
	animation_component.reset()

func _set_cost_icon(use_bitcoin: bool) -> void:
	use_btc_icon = use_bitcoin
	if use_bitcoin:
		btc_texture.visible = true
		fiat_texture.visible = false
	else:
		fiat_texture.visible = true
		btc_texture.visible = false

func change_labels(title: String, description: String, cost: float, is_maxed_out: bool = false) -> void:
	skill_title.text = title
	
	if description.is_empty():
		skill_description.hide()
	else:
		skill_description.text = description
	
	update_cost_label(cost, is_maxed_out)

func update_cost_label(cost: float, is_maxed_out: bool = false) -> void:
	_change_price_background(use_btc_icon, cost, is_maxed_out)
	
	skill_cost.text = "WELL DONE!" if is_maxed_out else "%.2f" % cost

func _change_price_background(use_bitcoin: bool, cost: float, is_maxed_out: bool = false) -> void:
	current_currency = _get_currency_balance(use_bitcoin)
	
	price_background.remove_theme_stylebox_override("panel")
	if is_maxed_out:
		price_background.add_theme_stylebox_override("panel", max_ugraded_style)
		return
	
	if _get_currency_balance(use_bitcoin) < cost:
		price_background.add_theme_stylebox_override("panel", cannot_afford_upgrade_style)
	else:
		price_background.add_theme_stylebox_override("panel", can_afford_upgrade_style)
	
	

func _get_currency_balance(use_bitcoin) -> float:
	if use_bitcoin:
		return BitcoinWallet.get_bitcoin_balance()
	else:
		return BitcoinWallet.get_fiat_balance()
