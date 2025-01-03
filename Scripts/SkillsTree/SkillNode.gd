class_name SkillNode extends Button

## The type of stat to upgrade.
enum STAT_TYPE {
	## Default state.
	NONE = 0,
	## Upgrades the player's health.
	HEALTH = 1,
	## Upgrades the player's speed.
	SPEED = 2,
	## Upgrades the player's damage multiplier.
	DAMAGE = 3}
enum FEATURE_TYPE {
	## Default state.
	NONE,
	## Unlocks a new weapon, the weapon_to_unlock must be specified. 
	WEAPON,
	## Unlocks a new player ability, not implement yet. 
	ABILITY,
	## Upgrades a player stat, like health, damage or speed.
	STAT_UPGRADE}

@export_category("Settings")
@export_group("General")
@export var use_bitcoin: bool = false
@export var is_unlocked: bool = false
@export var next_tier_nodes: Array[SkillNode]

@export_group("UI Settings")
## This settings will be used when the skill node is active.
@export var enabled_label_settings: LabelSettings
## This settings will be used when the skill node is locked i.e disabled.
@export var disabled_label_settings: LabelSettings
## When the currency to use is set to bitcoin
@export var bitcoin_icon: Texture2D
## When the currency to use is set to the dollar
@export var dollar_icon: Texture2D

@export_group("Upgrade Data Settings")
@export var skillnode_data : SkillNodeData
## If the data is an upgrade and not an unlock, this needs to be specified.
@export var stat_to_upgrade: PlayerStat
## The type of stat to upgrade.
@export var stat_type: STAT_TYPE

@export_group("Save Settings")
## A save name for the skillnode_data resource.
@export var save_name: String = ""


@onready var skill_line: Line2D = %SkillBranch
@onready var skill_label_status: Label = %SkillLabel
@onready var skill_info_panel: SkillInfoPanelInNode = $SkillInfoPanel
@onready var animation_component: AnimationComponentUI = $AnimationComponent
@onready var currency_icon: TextureRect = $CurrencyIcon

var is_maxed_out: bool = false
var node_identifier: int = 0
var current_upgrade_power: float = 0.0
var node_state: SkillNodeData.SKILL_NODE_STATUS = SkillNodeData.SKILL_NODE_STATUS.LOCKED
var SAVE_PATH: String = ""

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _enter_tree() -> void:
	if !skillnode_data: return
	SAVE_PATH = "user://saves/SkillsTree/{0}.tres".format([save_name])

	skillnode_data.upgrade_maxed.connect(_on_upgrade_maxed)
	skillnode_data.next_tier_unlocked.connect(_unlock_next_tier)

func _ready() -> void:
	if is_unlocked:
		unlock()
	else:
		lock()
	
	# if skillnode_data and skillnode_data.check_next_tier_unlock():
	# 	_unlock_next_tier()
	# if skillnode_data and skillnode_data.check_upgrade_maxed_out():
	# 	_on_upgrade_maxed()
	
	currency_icon.texture = bitcoin_icon if use_bitcoin else dollar_icon

# ___________________ PUBLIC FUNCTIONS ________________________

func lock() -> void:
	print_debug("Locked")
	# node_state = SkillNodeData.SKILL_NODE_STATUS.LOCKED
	# skillnode_data.set_upgrade_status(node_state)
	hide()
	_set_disabled_state(true)
	is_unlocked = false
	_update_skill_status_label("LOCKED", disabled_label_settings)
	_set_modulate_color(Color.GRAY)

func unlock() -> void:
	#print_debug("Unlocked")
	# node_state = SkillNodeData.SKILL_NODE_STATUS.UNLOCKED
	# self.skillnode_data.set_upgrade_status(node_state)
	show()
	_set_disabled_state(false)
	is_unlocked = true
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]), enabled_label_settings)
	_set_modulate_color(Color.WHITE)
	_unlock_or_upgrade()

func is_skill_unlocked() -> bool:
	return is_unlocked

func set_node_identifier(id: int = 0) -> void:
	node_identifier = id
	skillnode_data.set_id(id)

# _____________________PRIVATE FUNCTIONS________________________

func _unlock_or_upgrade() -> void:
	match skillnode_data.feature_type:
		FEATURE_TYPE.WEAPON:
			_unlock_weapon()
		FEATURE_TYPE.ABILITY:
			_unlock_ability()
		FEATURE_TYPE.STAT_UPGRADE:
			_upgrade_stat()
		FEATURE_TYPE.NONE:
			print_debug("Define a feature type...")

func _unlock_weapon() -> void:
	GameManager.unlock_weapon(Utils.weapon_name_to_string(skillnode_data.weapon_to_unlock))
	print("SkillNode: Unlocked new weapon-{0}".format([skillnode_data.weapon_to_unlock]))

func _unlock_ability() -> void:
	if skillnode_data.ability_to_unlock:
		# Implement the logic to unlock the ability
		print("Unlocked new ability: {0}".format(skillnode_data.ability_to_unlock))

func _upgrade_stat() -> void:
	current_upgrade_power += skillnode_data.apply_upgrade()
	GameManager.upgrade_stat(save_name, current_upgrade_power, stat_type)
	#print_debug("The {0} has now the value of {1}".format([stat_to_upgrade.resource_name, stat_to_upgrade.value]))

func _is_next_tier_node_unlocked() -> bool:
	for node in next_tier_nodes:
		return node.is_skill_unlocked()
	
	return false

# ______________________UI FUNCTIONS___________________________

## DEPRECATED
func update_ui() -> void:
	self.node_state = self.skillnode_data.get_upgrade_status()
	match self.node_state:
		SkillNodeData.SKILL_NODE_STATUS.LOCKED:
			hide()
			#_hide_next_node_line()
			_set_disabled_state(true)
			is_unlocked = false
			_update_skill_status_label("LOCKED", disabled_label_settings)
			_set_modulate_color(Color.GRAY)
		SkillNodeData.SKILL_NODE_STATUS.UNLOCKED:
			show()
			#_hide_next_node_line()
			_set_disabled_state(false)
			is_unlocked = true
			_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]), enabled_label_settings)
			_set_modulate_color(Color.WHITE)
		SkillNodeData.SKILL_NODE_STATUS.MAXED_OUT:
			show()
			#_hide_next_node_line()
			_unlock_next_tier()
			_set_disabled_state(true)
			_update_skill_status_label("MAXED")
			_set_modulate_color(Color.GOLD)

func _update_skill_status_label(new_text, label_settings: LabelSettings = null):
		skill_label_status.text = new_text
		skill_label_status.label_settings = enabled_label_settings
		skill_info_panel.update_cost_label(skillnode_data.upgrade_cost(), true)

func _hide_next_node_line() -> void:
	if next_tier_nodes.size() <= 0: return
	
	await get_tree().process_frame
	
	for node in next_tier_nodes:
		if _is_next_tier_node_unlocked():
			node.skill_line.show()
		else:
			node.skill_line.hide()

func _update_info_panel(cost: float) -> void:
	skill_info_panel.update_cost_label(cost, is_maxed_out)

# ______________________SETTERS___________________________________

func _set_disabled_state(state: bool) -> void:
	disabled = state

func _set_modulate_color(color: Color) -> void:
	self_modulate = color

func _set_line_points() -> void:
	skill_line.clear_points()
	
	for node in next_tier_nodes:
		# Calculate the center of the current node in global coordinates
		var current_node_center_global = global_position + self.get_global_rect().size / 2
		# Calculate the center of the next tier node in global coordinates
		var next_node_center_global = node.global_position + node.get_global_rect().size / 2

		# Convert global positions to local positions relative to the Line2D node
		var current_node_center_local = skill_line.to_local(current_node_center_global)
		var parent_node_center_local = skill_line.to_local(next_node_center_global)
	
		skill_line.add_point(current_node_center_local)
		skill_line.add_point(parent_node_center_local)

# _______________________SIGNALS__________________________________

func _on_mouse_entered() -> void:
	skill_info_panel.activate_panel(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(), use_bitcoin, is_maxed_out)

func _on_mouse_exited() -> void:
	skill_info_panel.deactivate_panel()

func _on_skill_pressed() -> void:
	if not _buy_upgrade():
		return
	
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]), enabled_label_settings)
	_update_info_panel(skillnode_data.upgrade_cost())
	_unlock_or_upgrade()

func _buy_upgrade() -> bool:
	return skillnode_data.buy_upgrade(use_bitcoin)

func _on_upgrade_maxed() -> void:
	show()
	is_maxed_out = true
	_set_disabled_state(true)
	_update_skill_status_label("MAXED")
	_set_modulate_color(Color.GOLD)
	_unlock_next_tier()
	_unlock_or_upgrade()

func _unlock_next_tier() -> void:
	for node in next_tier_nodes:
		if node.is_unlocked:
			continue  # Skip nodes that are already unlocked
		node.unlock()

# ________________________PERSISTENCE FUNCTIONS__________________________


func save_data() -> void:
	# I don't think is necesary to save the entire resource, I can save only the upgrade_level and upgrade_max_level
	# var data = skillnode_data.duplicate(true)
	# var error = ResourceSaver.save(data, SAVE_PATH)
	# if error != OK:
	# 	print_debug("Error saving data: {0}".format([error]))
	# else:
	# 	print_debug("Saved data: {0}".format([skillnode_data]))

	#GameManager.set_resource_to_game_data_dic(skillnode_data, GameManager.ResourceDataType.SkillNodeData, save_name)
	#GameManager.game_data_to_save.skill_nodes_data_dic[save_name] = skillnode_data

	SaveSystem.set_var(save_name if !save_name.is_empty() else skillnode_data.upgrade_name, self._build_save_dictionary())
	# var error = ResourceSaver.save(skillnode_data, SAVE_PATH)
	# if error != OK:
	# 	print("Error saving data: {0}".format([error]))

func _build_save_dictionary() -> Dictionary:
	return {
		"upgrade_level": skillnode_data.upgrade_level,
		"node_state": skillnode_data.status
	}

func load_data() -> void:
	var saved_name: String = save_name if !save_name.is_empty() else skillnode_data.upgrade_name
	if !SaveSystem.has(saved_name):
		print("No data upgrade data found in node {0}".format([self.name]))
		return
	var data: Dictionary = SaveSystem.get_var(saved_name)
	
	skillnode_data.upgrade_level = data["upgrade_level"]
	skillnode_data.status = data["node_state"]
	
	# if skillnode_data.check_next_tier_unlock():
	# 	_unlock_next_tier()
	# if skillnode_data.check_upgrade_maxed_out():
	# 	_on_upgrade_maxed()
	# _unlock_or_upgrade()
	if !is_maxed_out:
		_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]), enabled_label_settings)
