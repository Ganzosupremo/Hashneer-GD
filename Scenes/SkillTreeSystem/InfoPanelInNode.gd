class_name SkillInfoPanelInNode extends Control

@export var icon_cost_texture: Texture2D


@onready var skill_title: Label = $PanelContainer/VBoxContainer/SkillTitle
@onready var skill_description: RichTextLabel = $PanelContainer/VBoxContainer/SkillDescription
@onready var skill_cost: Label = $PanelContainer/VBoxContainer/HBoxContainer/SkillCost
@onready var icon: TextureRect = $PanelContainer/VBoxContainer/HBoxContainer/Icon


func _ready() -> void:
	if icon_cost_texture != null:
		icon.texture = icon_cost_texture
	
	visible = false

func activate_panel(title: String, description: String, cost: String) -> void:
	change_labels(title, description, cost)
	visible = true

func deactivate_panel() -> void:
	visible = false

func change_labels(title: String, description: String, cost: String) -> void:
	skill_title.text = title
	skill_description.text = description
	skill_cost.text = cost

func update_cost_label(cost: String) -> void:
	skill_cost.text = cost
