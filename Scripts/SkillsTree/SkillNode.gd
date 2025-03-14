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
## When the skillnode is maxed out, this icon will be displayed.
@export var icon_on_maxed_out: Texture2D

@export_subgroup("On Click Sound Effects (Optional)")
@export var on_mouse_entered_effect: SoundEffectDetails
@export var on_mouse_down_effect: SoundEffectDetails
@export var on_mouse_up_effect: SoundEffectDetails

@export_group("Skill Node Data Settings")
@export var skillnode_data : SkillNodeData
## If the data is an upgrade and not an unlock, this needs to be specified.
@export var dstat_to_upgrade: PlayerStat
## The type of stat to upgrade.
@export var stat_type: STAT_TYPE

@export_group("Save Settings")
## A save name for the skillnode_data resource.
@export var save_name: String = ""


@onready var skill_line: Line2D = %SkillBranch
@onready var skill_label_status: Label = %SkillLabel
@onready var skill_info_panel: SkillInfoPanelInNode = $SkillInfoPanel
@onready var sound_effect_component_ui: SoundEffectComponentUI = $SoundEffectComponentUI
@onready var currency_icon: TextureRect = %CurrencyIcon

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
	
	set_currecy_icon(use_bitcoin)

# ___________________ PUBLIC FUNCTIONS ________________________

func lock() -> void:
	hide()
	_set_disabled_state(true)
	is_unlocked = false
	_update_skill_status_label("LOCKED", disabled_label_settings, is_maxed_out)
	_set_modulate_color(Color.GRAY)

func unlock() -> void:
	show()
	_set_disabled_state(false)
	is_unlocked = true
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]), enabled_label_settings, is_maxed_out)
	_set_modulate_color(Color.WHITE)

func is_skill_unlocked() -> bool:
	return is_unlocked

func set_node_identifier(id: int = 0) -> void:
	node_identifier = id
	skillnode_data.set_id(id)

func is_next_tier_unlocked() -> bool:
	return skillnode_data.check_next_tier_unlock()

func is_this_skill_maxed_out() -> bool:
	return skillnode_data.check_upgrade_maxed_out()
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
	#print("SkillNode: Unlocked new weapon-{0}".format([skillnode_data.weapon_to_unlock]))

func _unlock_ability() -> void:
	if skillnode_data.ability_to_unlock_id == "":
		# print_debug("No ability_id set in skillnode_data.")
		return
	
	GameManager.register_unlocked_ability(skillnode_data.ability_to_unlock_id)
		# Implement the logic to unlock the ability
		#print("Unlocked new ability: {0}".format(skillnode_data.ability_to_unlock))

func _upgrade_stat() -> void:
	current_upgrade_power = skillnode_data.apply_upgrade()
	GameManager.upgrade_stat(Utils.player_stat_type_to_string(stat_type), current_upgrade_power, stat_type)

func _is_next_tier_node_unlocked() -> bool:
	for node in next_tier_nodes:
		return node.is_skill_unlocked()
	
	return false

func _buy_upgrade() -> bool:
	return skillnode_data.buy_upgrade(use_bitcoin)

# ______________________UI FUNCTIONS___________________________

func _update_icon_on_maxed_out() -> void:
	icon = icon_on_maxed_out
	currency_icon.visible = false

func _update_skill_status_label(new_text, label_settings: LabelSettings = null, maxed_out: bool = false):
		skill_label_status.text = new_text
		if label_settings != null:
			skill_label_status.label_settings = label_settings
		_update_info_panel(skillnode_data.upgrade_cost(use_bitcoin), maxed_out)

func _hide_next_node_line() -> void:
	if next_tier_nodes.size() <= 0: return
	
	await get_tree().process_frame
	
	for node in next_tier_nodes:
		if _is_next_tier_node_unlocked():
			node.skill_line.show()
		else:
			node.skill_line.hide()

func _update_info_panel(cost: float, maxed_out: bool = false) -> void:
	skill_info_panel.update_cost_label(int(cost), maxed_out)

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

func set_use_btc_as_currency(new_value: bool) -> void:
	use_bitcoin = new_value
	set_currecy_icon(use_bitcoin)
	skill_info_panel.update_cost_label(skillnode_data.upgrade_cost(use_bitcoin), use_bitcoin, is_maxed_out)

func set_currecy_icon(btc_icon: bool) -> void:
	currency_icon.texture = bitcoin_icon if btc_icon else dollar_icon

# _______________________SIGNALS__________________________________

func _on_mouse_entered() -> void:
	skill_info_panel.activate_panel(skillnode_data.upgrade_name, skillnode_data.upgrade_description, int(skillnode_data.upgrade_cost(use_bitcoin)), use_bitcoin, is_maxed_out)
	if sound_effect_component_ui == null: return
	sound_effect_component_ui.set_and_play_sound(on_mouse_entered_effect)

func _on_mouse_exited() -> void:
	skill_info_panel.deactivate_panel()

func _on_skill_pressed() -> void:
	if not _buy_upgrade():
		return
	
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]), enabled_label_settings, is_maxed_out)
	_update_info_panel(skillnode_data.upgrade_cost(use_bitcoin), is_maxed_out)
	_unlock_or_upgrade()

func _on_button_down() -> void:
	if sound_effect_component_ui == null: return
	sound_effect_component_ui.set_and_play_sound(on_mouse_down_effect)

func _on_button_up() -> void:
	if sound_effect_component_ui == null: return
	sound_effect_component_ui.set_and_play_sound(on_mouse_up_effect)

func _on_upgrade_maxed() -> void:
	show()
	is_maxed_out = true
	_set_disabled_state(true)
	_update_skill_status_label("MAXED", disabled_label_settings, is_maxed_out)
	_update_icon_on_maxed_out()
	_unlock_next_tier()
	_unlock_or_upgrade()

func _unlock_next_tier() -> void:
	for node in next_tier_nodes:
		if node.is_unlocked:
			continue  # Skip nodes that are already unlocked
		node.unlock()

# ________________________PERSISTENCE FUNCTIONS__________________________


func save_data() -> void:
	SaveSystem.set_var(save_name if !save_name.is_empty() else skillnode_data.upgrade_name, self._build_save_dictionary())

func _build_save_dictionary() -> Dictionary:
	return {
		"upgrade_level": skillnode_data.upgrade_level,
		"node_state": skillnode_data.status
	}

func load_data() -> void:
	var saved_name: String = save_name if !save_name.is_empty() else skillnode_data.upgrade_name
	if !SaveSystem.has(saved_name):
		# print("No data upgrade data found in node {0}".format([self.name]))
		return
	var data: Dictionary = SaveSystem.get_var(saved_name)
	
	skillnode_data.upgrade_level = data["upgrade_level"]
	skillnode_data.status = data["node_state"]
	
	if is_next_tier_unlocked():
		_unlock_next_tier()
	if is_this_skill_maxed_out():
		_on_upgrade_maxed()
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]), enabled_label_settings, is_maxed_out)
	
