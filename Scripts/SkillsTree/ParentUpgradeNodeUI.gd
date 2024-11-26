class_name ParentUpgradeNodeUI extends Control

@export_category("Children Node's Aesthetics")
@export var active_texture: Texture2D
@export var max_level_texture: Texture2D
@export var disabled_texture: Texture2D

@export_category("Upgrade's Data")
## The data containing all parameters for am upgrade in bitcoin terms
@export var bitcoin_upgrade_data: UpgradeData
## The data containing all parameters for an upgrade in fiat terms
@export var fiat_upgrade_data: UpgradeData
@export var upgrade_type: SkillNode.UPGRADE_TYPE


var children: Array = []

func _ready() -> void:
	children = get_children()
	
	for child in children:
		child.set_textures(active_texture, max_level_texture, disabled_texture)
		if child.use_bitcoin:
			child.set_upgrade_data(bitcoin_upgrade_data, upgrade_type)
		else:
			child.set_upgrade_data(fiat_upgrade_data, upgrade_type)
