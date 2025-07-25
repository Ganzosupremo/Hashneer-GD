class_name SkillNode extends Button
## SkillNode represents a node in the skill tree that can be upgraded by the player.
## 
## It contains information about the skill, its _cost, and its current state.
## It also handles the UI representation of the skill node, including its icon, _title, description, and _cost.


## Represents the current UI state of the node.
enum NodeState {
	UNKNOWN,
	## The node is locked and cannot be interacted with.
	## This is the default state.
	LOCKED,
	## The node is unlocked and cannot be interacted with.
	## The player does not have enough currency to purchase the upgrade.
	CANNOT_AFFORD,
	## The node is unlocked and can be interacted with.
	## The player has enough currency to purchase the upgrade.
	CAN_AFFORD,
	## The node is unlocked and cannot be interacted with.
	## The player has purchased the maximum level of the upgrade.
	MAXED_OUT
}

@export_category("Event Bus")
## Main event bus for the game.
@export var main_event_bus: MainEventBus

@export_category("Settings")
@export_group("General")
## The player progress event bus to use for this skill node.
@export var progress_event_bus: PlayerProgressEventBus
## If [code]true[/code], the skill node will be unlocked by default.
@export var is_unlocked: bool = false
## The next tier nodes that this skill node can unlock.
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
## The style to use when the skill node can be afforded.
@export var can_afford_style: StyleBoxTexture
## The style to use when the skill node cannot be afforded.
@export var cannot_afford_style: StyleBoxTexture
## The style to use when the skill node is maxed out.
@export var max_upgraded_style: StyleBoxTexture

@export_subgroup("On Click Sound Effects (Optional)")
## The sound effect to play when the mouse enters the skill node.
@export var on_mouse_entered_effect: SoundEffectDetails
## The sound effect to play when the skill node is pressed.
@export var on_mouse_down_effect: SoundEffectDetails
## The sound effect to play when the skill node is released.
@export var on_mouse_up_effect: SoundEffectDetails

@export_group("Skill Node Data Settings")
## The data resource that contains the skill node's upgrade information.
## It contains the upgrade name, description, _cost, and other related information.
@export var skillnode_data : UpgradeData

@export_group("Save Settings")
## A save name for the skillnode_data resource.
@export var save_name: String = ""


@onready var _skill_line: Line2D = %SkillBranch
@onready var _skill_label_status: Label = %SkillLabel
@onready var _sound_effect_component_ui: SoundEffectComponentUI = $SoundEffectComponentUI
@onready var _currency_icon: TextureRect = %CurrencyIcon
@onready var _progress_bar: TextureProgressBar = %LevelProgressBar

@onready var _title: Label = %Title
@onready var _skill_node_texture: TextureRect = %SkillNodeTexture
@onready var _desc: Label = %Desc
@onready var _cost_background: PanelContainer = %CostBackground
@onready var _cost: Label = %Cost

var _is_maxed_out: bool = false
var _node_identifier: int = 0
var _node_state: NodeState = NodeState.LOCKED
var _upgrade_logic: SkillUpgrade

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _enter_tree() -> void:
	if skillnode_data:
		_upgrade_logic = SkillUpgrade.new(skillnode_data, next_tier_nodes)
	
	if !_upgrade_logic.upgrade_maxed.is_connected(_on_upgrade_maxed) and !_upgrade_logic.level_changed.is_connected(_on_level_changed):
		_upgrade_logic.upgrade_maxed.connect(_on_upgrade_maxed)
		_upgrade_logic.level_changed.connect(_on_level_changed)
		_upgrade_logic.update_ui.connect(_on_ui_updated)

func _exit_tree() -> void:
	_upgrade_logic.upgrade_maxed.disconnect(_on_upgrade_maxed)
	_upgrade_logic.level_changed.disconnect(_on_level_changed)
	main_event_bus.currency_changed.disconnect(_on_currency_changed)
	_upgrade_logic.reset_next_tier_nodes_array()
	skillnode_data.reset_next_tier_nodes()

func _ready() -> void:
	if skillnode_data:
		skillnode_data.set_next_tier_nodes(self.next_tier_nodes)
		_upgrade_logic = SkillUpgrade.new(skillnode_data, next_tier_nodes)
		_upgrade_logic.upgrade_maxed.connect(_on_upgrade_maxed)
		_upgrade_logic.level_changed.connect(_on_level_changed)
	
	main_event_bus.currency_changed.connect(_on_currency_changed)
	_progress_bar.show()
	if is_unlocked:
		unlock()
	else:
		lock()
	_update_node_line_points()
	var current_currency := UpgradeService.current_currency
	set_currency_icon(current_currency)
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(current_currency))
	_update_node_state()

#region Public API

func lock() -> void:
	hide()
	_set_disabled_state(true)
	is_unlocked = false
	_update_skill_status_label("LOCKED")
	_set_modulate_color(Color.GRAY)
	_update_node_line_points()
	_update_node_state()

func unlock() -> void:
	show()
	_set_disabled_state(false)
	is_unlocked = true
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, skillnode_data.upgrade_max_level]))
	_set_modulate_color(Color.WHITE)
	_update_node_line_points()
	_update_node_state()

func is_node_unlocked() -> bool:
	return is_unlocked

func set_node_identifier(id: int = 0) -> void:
	_node_identifier = id
	skillnode_data.set_id(id)

func is_next_tier_unlocked() -> bool:
	return skillnode_data.check_next_tier_unlock(self.next_tier_nodes)

func is_this_skill_maxed_out() -> bool:
	return skillnode_data.check_upgrade_maxed_out()

func apply_random_economic_event(_economic_event: EconomicEvent) -> void:
	if _upgrade_logic:
		_upgrade_logic.apply_random_economic_event(_economic_event)

func revert_economic_event_effects() -> void:
	"""Reverts the effects of economic events on this skill node."""
	if _upgrade_logic:
		_upgrade_logic.revert_economic_event_effects()

#endregion

#region UI functions

func _on_ui_updated() -> void:
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(UpgradeService.current_currency))
	_update_node_state()
	_update_progress_bar(skillnode_data.upgrade_level, skillnode_data.upgrade_max_level)
	_update_node_line_points()

func _update_skill_status_label(_text: String):
		_skill_label_status.text = _text

func _update_progress_bar(value: float, max_value: float) -> void:
	_progress_bar.max_value = max_value
	_progress_bar.value = value

func _update_node_line_points() -> void:
	# Clear the current points on the line.
	_skill_line.clear_points()

	# Calculate the center of this node.
	var self_center: Vector2 = global_position + get_global_rect().size / 2
	var any_visible: bool = false

	for node in next_tier_nodes:
		if node.is_node_unlocked():
			any_visible = true
			# Calculate the center of the next tier node.
			var next_node_center: Vector2 = node.global_position + node.get_global_rect().size / 2

			# Convert the global positions to local positions relative to the Line2D node.
			var self_center_local: Vector2 = _skill_line.to_local(self_center)
			var next_node_center_local: Vector2 = _skill_line.to_local(next_node_center)

			# Add the points to the line.
			_skill_line.add_point(self_center_local)
			_skill_line.add_point(next_node_center_local)
	
	if !any_visible:
		_skill_line.hide()
	_skill_line.show()

func _update_skill_node_ui(_title_l: String, _description: String, _cost_l: float) -> void:
		self._title.text = _title_l
		var texture: Texture2D = icon_on_maxed_out if _is_maxed_out else skill_icon
		self._skill_node_texture.texture = texture
		self._desc.text = _description
		self._cost.text = Utils.format_currency(_cost_l, true)
		_update_cost_background()

func _update_node_state() -> void:
	if !is_unlocked:
		_node_state = NodeState.LOCKED
	elif _is_maxed_out or skillnode_data.upgrade_level >= skillnode_data.upgrade_max_level:
		_node_state = NodeState.MAXED_OUT
		_is_maxed_out = true
	elif UpgradeService.can_afford(skillnode_data):
		_node_state = NodeState.CAN_AFFORD
	else:
		_node_state = NodeState.CANNOT_AFFORD
	_update_cost_background()

func _update_cost_background() -> void:
	_cost_background.remove_theme_stylebox_override("panel")
	match _node_state:
		NodeState.MAXED_OUT:
			_cost_background.add_theme_stylebox_override("panel", max_upgraded_style)
		NodeState.CANNOT_AFFORD:
			_cost_background.add_theme_stylebox_override("panel", cannot_afford_style)
		NodeState.CAN_AFFORD:
			_cost_background.add_theme_stylebox_override("panel", can_afford_style)

#endregion

#region Setters

func _set_disabled_state(state: bool) -> void:
	disabled = state

func _set_modulate_color(color: Color) -> void:
	self_modulate = color

func _set_line_points() -> void:
	_skill_line.clear_points()
	
	for node in next_tier_nodes:
		# Calculate the center of the current node in global coordinates
		var current_node_center_global = global_position + self.get_global_rect().size / 2
		# Calculate the center of the next tier node in global coordinates
		var next_node_center_global = node.global_position + node.get_global_rect().size / 2

		# Convert global positions to local positions relative to the Line2D node
		var current_node_center_local = _skill_line.to_local(current_node_center_global)
		var parent_node_center_local = _skill_line.to_local(next_node_center_global)
	
		_skill_line.add_point(current_node_center_local)
		_skill_line.add_point(parent_node_center_local)

func _on_currency_changed(currency: Constants.CurrencyType) -> void:
	set_currency_icon(currency)
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(currency))
	_update_node_state()

func set_currency_icon(currency: Constants.CurrencyType) -> void:
	match currency:
		Constants.CurrencyType.BITCOIN:
			_currency_icon.texture = bitcoin_icon
		Constants.CurrencyType.FIAT:
			_currency_icon.texture = dollar_icon
		_:
			_currency_icon.texture = null  # Fallback if an unknown currency is used

#endregion

#region Signals

func _on_mouse_entered() -> void:
	if _sound_effect_component_ui == null: return
	_sound_effect_component_ui.set_and_play_sound(on_mouse_entered_effect)

func _on_skill_pressed() -> void:
	if not _upgrade_logic.purchase():
		return

	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(UpgradeService.current_currency))
	_update_node_state()

func _on_button_down() -> void:
	if _sound_effect_component_ui == null: return
	_sound_effect_component_ui.set_and_play_sound(on_mouse_down_effect)

func _on_button_up() -> void:
	if _sound_effect_component_ui == null: return
	_sound_effect_component_ui.set_and_play_sound(on_mouse_up_effect)

func _on_upgrade_maxed() -> void:
	show()
	_is_maxed_out = true
	_update_skill_status_label("Maxed")
	_set_disabled_state(true)
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(UpgradeService.current_currency))
	_unlock_next_tier()
	_update_node_state()

func _unlock_next_tier() -> void:
	for node in next_tier_nodes:
		if node.is_unlocked:
			continue  # Skip nodes that are already unlocked
		node.unlock()

func _on_level_changed(new_level: int, max_level: int) -> void:
	_update_skill_status_label("{0}/{1}".format([new_level, max_level]))
	_update_progress_bar(new_level, max_level)
	_update_node_state()

#endregion

#region Persistence data functions

func save_data() -> void:
	SaveSystem.set_var(save_name if !save_name.is_empty() else skillnode_data.upgrade_name, self._build_save_dictionary())

func _build_save_dictionary() -> Dictionary:
	return {
		"upgrade_level": skillnode_data.upgrade_level,
		"node_state": _node_state,
		"is_unlocked": is_unlocked,
		"is_maxed_out": _is_maxed_out,
		# Save economic event related data
		"original_upgrade_cost_base": skillnode_data.get_original_upgrade_cost_base(),
		"original_upgrade_cost_base_btc": skillnode_data.get_original_upgrade_cost_base_btc(),
		"has_stored_original_values": skillnode_data._has_stored_original_values,
		"current_upgrade_cost_base": skillnode_data.get_upgrade_cost_base(),
		"current_upgrade_cost_base_btc": skillnode_data.get_upgrade_cost_base_btc()
	}

func load_data() -> void:
	var saved_name: String = save_name if !save_name.is_empty() else skillnode_data.upgrade_name
	if !SaveSystem.has(saved_name):
		return
	var data: Dictionary = SaveSystem.get_var(saved_name)
	
	skillnode_data.upgrade_level = data["upgrade_level"]
	_node_state = Utils.int_to_skill_node_state(data["node_state"])
	_is_maxed_out = data["is_maxed_out"]
	is_unlocked = data["is_unlocked"]
	
	# Restore economic event related data
	if data.has("has_stored_original_values") and data["has_stored_original_values"]:
		skillnode_data.set_original_upgrade_cost_base(data.get("original_upgrade_cost_base", skillnode_data.upgrade_cost_base))
		skillnode_data.set_original_upgrade_cost_base_btc(data.get("original_upgrade_cost_base_btc", skillnode_data.upgrade_cost_base_btc))
		skillnode_data._has_stored_original_values = true
		
		# Restore the modified costs (in case an event was active when saved)
		skillnode_data.set_upgrade_cost_base(data.get("current_upgrade_cost_base", skillnode_data.upgrade_cost_base))
		skillnode_data.set_upgrade_cost_base_btc(data.get("current_upgrade_cost_base_btc", skillnode_data.upgrade_cost_base_btc))
	
	is_next_tier_unlocked()
	is_this_skill_maxed_out()
	
	_update_skill_node_ui(skillnode_data.upgrade_name, \
	skillnode_data.upgrade_description, \
	skillnode_data.upgrade_cost(UpgradeService.current_currency))

	_update_node_state()
	
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, \
	skillnode_data.upgrade_max_level]) if !_is_maxed_out else "Maxed")
	
	_update_progress_bar(skillnode_data.upgrade_level, skillnode_data.upgrade_max_level)
	_update_node_line_points()
	
#endregion
