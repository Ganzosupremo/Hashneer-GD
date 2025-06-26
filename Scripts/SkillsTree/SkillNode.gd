class_name SkillNode extends Button

enum FEATURE_TYPE {
	## Default state.
	NONE,
	## Unlocks a new weapon, the weapon_to_unlock must be specified. 
	WEAPON,
	## Unlocks a new player ability, not implement yet. 
	ABILITY,
	## Upgrades a player stat, like health, damage or speed.
	STAT_UPGRADE}

@export_category("Event Bus")
@export var main_event_bus: MainEventBus

@export_category("Settings")
@export_group("General")
@export var progress_event_bus: PlayerProgressEventBus
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
## When the skill node is maxed out, this icon will be displayed.
@export var icon_on_maxed_out: Texture2D
## The normal icon for the skill node.
@export var skill_icon: Texture2D

@export_subgroup("Cost Backgroung Styles")
@export var can_afford_style: StyleBoxTexture
@export var cannot_afford_style: StyleBoxTexture
@export var max_upgraded_style: StyleBoxTexture

@export_subgroup("On Click Sound Effects (Optional)")
@export var on_mouse_entered_effect: SoundEffectDetails
@export var on_mouse_down_effect: SoundEffectDetails
@export var on_mouse_up_effect: SoundEffectDetails

@export_group("Skill Node Data Settings")
@export var skillnode_data : SkillNodeData

@export_group("Save Settings")
## A save name for the skillnode_data resource.
@export var save_name: String = ""


@onready var skill_line: Line2D = %SkillBranch
@onready var skill_label_status: Label = %SkillLabel
# @onready var skill_info_panel: SkillInfoPanelInNode = $SkillInfoPanel
@onready var sound_effect_component_ui: SoundEffectComponentUI = $SoundEffectComponentUI
@onready var currency_icon: TextureRect = %CurrencyIcon
@onready var progress_bar: TextureProgressBar = %LevelProgressBar

@onready var title: Label = %Title
@onready var skill_node_texture: TextureRect = %SkillNodeTexture
@onready var desc: Label = %Desc
@onready var cost_background: PanelContainer = %CostBackground
@onready var cost: Label = %Cost

var is_maxed_out: bool = false
var node_identifier: int = 0
var node_state: SkillNodeData.DataStatus = SkillNodeData.DataStatus.LOCKED

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _enter_tree() -> void:
	if !skillnode_data: return

	main_event_bus.use_btc_toggled_ui.connect(set_use_btc_as_currency)
	skillnode_data.upgrade_maxed.connect(_on_upgrade_maxed)
	skillnode_data.next_tier_unlocked.connect(_unlock_next_tier)
	skillnode_data.upgrade_level_changed.connect(_on_level_changed)

func _ready() -> void:
	progress_bar.show()
	if is_unlocked:
		unlock()
	else:
		lock()
	_update_node_line_points()
	set_currency_icon(use_bitcoin)
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(use_bitcoin))

#region Public API

func lock() -> void:
	hide()
	_set_disabled_state(true)
	is_unlocked = false
	_update_skill_status_label("LOCKED")
	_set_modulate_color(Color.GRAY)
	_update_node_line_points()

func unlock() -> void:
	show()
	_set_disabled_state(false)
	is_unlocked = true
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]))
	_set_modulate_color(Color.WHITE)
	_update_node_line_points()

func is_node_unlocked() -> bool:
	return is_unlocked

func set_node_identifier(id: int = 0) -> void:
	node_identifier = id
	skillnode_data.set_id(id)

func is_next_tier_unlocked() -> bool:
	return skillnode_data.check_next_tier_unlock()

func is_this_skill_maxed_out() -> bool:
	return skillnode_data.check_upgrade_maxed_out()
	
#endregion

#region Private functions

func _unlock_or_upgrade() -> void:
	match skillnode_data.feature_type:
		FEATURE_TYPE.WEAPON:
			_unlock_weapon()
		FEATURE_TYPE.ABILITY:
			_unlock_ability()
		FEATURE_TYPE.STAT_UPGRADE:
			_upgrade_stat()
		FEATURE_TYPE.NONE:
			push_error("Define a feature type...")

func _unlock_weapon() -> void:
		progress_event_bus.unlock_weapon(Utils.weapon_name_to_string(
				skillnode_data.weapon_data.weapon_type), skillnode_data.weapon_data.weapon_to_unlock)

func _unlock_ability() -> void:
		progress_event_bus.unlock_ability(Utils.ability_name_to_string(
				skillnode_data.ability_data.ability_type
				), skillnode_data.ability_data.ability_to_unlock)

func _upgrade_stat() -> void:
		progress_event_bus.upgrade_stat(Utils.player_stat_type_to_string(skillnode_data.stat_type), skillnode_data.get_current_power(), skillnode_data.is_percentage)

func _is_next_tier_node_unlocked() -> bool:
		if next_tier_nodes.is_empty():
				return false

		for node in next_tier_nodes:
				if !node.is_node_unlocked():
						return false

		return true

func _buy_upgrade() -> bool:
	return skillnode_data.buy_upgrade(use_bitcoin)

#endregion

#region UI functions

func _update_skill_status_label(_text: String):
		skill_label_status.text = _text

func _update_progress_bar(value: float, max_value: float) -> void:
	progress_bar.max_value = max_value
	progress_bar.value = value

func _update_node_line_points() -> void:
	# Clear the current points on the line.
	skill_line.clear_points()

	# Calculate the center of this node.
	var self_center: Vector2 = global_position + get_global_rect().size / 2
	var any_visible: bool = false

	for node in next_tier_nodes:
		if node.is_node_unlocked():
			any_visible = true
			# Calculate the center of the next tier node.
			var next_node_center: Vector2 = node.global_position + node.get_global_rect().size / 2

			# Convert the global positions to local positions relative to the Line2D node.
			var self_center_local: Vector2 = skill_line.to_local(self_center)
			var next_node_center_local: Vector2 = skill_line.to_local(next_node_center)

			# Add the points to the line.
			skill_line.add_point(self_center_local)
			skill_line.add_point(next_node_center_local)
	
	if !any_visible:
		skill_line.hide()
	skill_line.show()

func _update_skill_node_ui(_title: String, _desc: String, _cost: float) -> void:
	title.text = _title
	var texture: Texture2D = icon_on_maxed_out if is_maxed_out else skill_icon
	skill_node_texture.texture = texture
	desc.text = _desc
	cost.text = Utils.format_currency(_cost, true)
	_update_cost_background()

func _update_cost_background() -> void:
	cost_background.remove_theme_stylebox_override("panel")
	var balance: float = BitcoinWallet.get_bitcoin_balance() if use_bitcoin else BitcoinWallet.get_fiat_balance()
	var s_cost: float = skillnode_data.upgrade_cost(use_bitcoin)
	
	if is_maxed_out: 
		cost_background.add_theme_stylebox_override("panel", max_upgraded_style)
	if balance <= s_cost and !is_maxed_out:
		cost_background.add_theme_stylebox_override("panel", cannot_afford_style)
	if balance >= s_cost and !is_maxed_out:
		cost_background.add_theme_stylebox_override("panel", can_afford_style)

#endregion

#region Setters

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

func set_use_btc_as_currency(toggled_on: bool) -> void:
	use_bitcoin = toggled_on
	skillnode_data.use_bitcoin = toggled_on
	set_currency_icon(use_bitcoin)
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(use_bitcoin))

func set_currency_icon(btc_icon: bool) -> void:
	currency_icon.texture = bitcoin_icon if btc_icon else dollar_icon

#endregion

#region Signals

func _on_mouse_entered() -> void:
	# skill_info_panel.activate_panel(skillnode_data.upgrade_name, skillnode_data.upgrade_description, int(skillnode_data.upgrade_cost(use_bitcoin)), use_bitcoin, is_maxed_out)
	if sound_effect_component_ui == null: return
	sound_effect_component_ui.set_and_play_sound(on_mouse_entered_effect)


func _on_skill_pressed() -> void:
	if not _buy_upgrade():
		return
		
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(use_bitcoin))
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
	_update_skill_status_label("Maxed")
	_set_disabled_state(true)
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(use_bitcoin))
	_unlock_next_tier()
	_unlock_or_upgrade()

func _unlock_next_tier() -> void:
	for node in next_tier_nodes:
		if node.is_unlocked:
			continue  # Skip nodes that are already unlocked
		node.unlock()

func _on_level_changed(new_level: int, max_level: int) -> void:
	_update_skill_status_label("{0}/{1}".format([new_level, max_level]))
	_update_progress_bar(new_level, max_level)

#endregion

#region Persistence data functions

func save_data() -> void:
	SaveSystem.set_var(save_name if !save_name.is_empty() else skillnode_data.upgrade_name, self._build_save_dictionary())

func _build_save_dictionary() -> Dictionary:
	return {
		"upgrade_level": skillnode_data.upgrade_level,
		"node_state": skillnode_data.status,
		"is_unlocked": is_unlocked,
		"is_maxed_out": is_maxed_out
	}

func load_data() -> void:
	var saved_name: String = save_name if !save_name.is_empty() else skillnode_data.upgrade_name
	if !SaveSystem.has(saved_name):
		return
	var data: Dictionary = SaveSystem.get_var(saved_name)
	
	skillnode_data.upgrade_level = data["upgrade_level"]
	skillnode_data.status = data["node_state"]
	is_maxed_out = data["is_maxed_out"]
	is_unlocked = data["is_unlocked"]
	
	is_next_tier_unlocked()
	is_this_skill_maxed_out()
	
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(use_bitcoin))
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]) if !is_maxed_out else "Maxed")
	_update_progress_bar(skillnode_data.upgrade_level, skillnode_data.upgrade_max_level)
	_update_node_line_points()
	
#endregion
