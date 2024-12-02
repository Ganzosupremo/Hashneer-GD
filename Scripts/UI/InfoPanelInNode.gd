class_name SkillInfoPanelInNode extends Control

@export var use_btc_icon: bool = true

@onready var skill_title: Label = $PanelContainer/VBoxContainer/SkillTitle
@onready var skill_description: RichTextLabel = $PanelContainer/VBoxContainer/SkillDescription
@onready var skill_cost: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCost
@onready var fiat_texture: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/FiatTexture
@onready var btc_texture: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/BTCTexture
@onready var animation_component: AnimationComponentUI = $AnimationComponent


func _ready() -> void:
	visible = false

func activate_panel(title: String, description: String, cost: String, use_bitcoin: bool) -> void:
	change_labels(title, description, cost)
	set_cost_icon(use_bitcoin)
	visible = true
	animation_component.start_tween()

func deactivate_panel() -> void:
	visible = false
	animation_component.reset()

func set_cost_icon(use_bitcoin: bool) -> void:
	use_btc_icon = use_bitcoin
	if use_bitcoin:
		btc_texture.visible = true
		fiat_texture.visible = false
	else:
		fiat_texture.visible = true
		btc_texture.visible = false

func toggle_panel(title: String, description: String, cost: String) -> void:
	change_labels(title, description, cost)
	visible != visible

func change_labels(title: String, description: String, cost: String) -> void:
	skill_title.text = title
	
	if description.is_empty():
		skill_description.hide()
	else:
		skill_description.text = description
	
	skill_cost.text = cost

func update_cost_label(cost: String) -> void:
	skill_cost.text = "%.2f" % cost
