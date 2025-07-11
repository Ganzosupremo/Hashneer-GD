class_name SkillNode extends Button

## Represents the current UI state of the node.
enum NodeState {
		UNKNOWN,
		## The node is locked and cannot be interacted with.
		## This is the default state.
		LOCKED,
		## The node is unlocked and can be interacted with.
		## The player does not have enough currency to purchase the upgrade.
		CANNOT_AFFORD,
		## The node is unlocked and can be interacted with.
		## The player has enough currency to purchase the upgrade.
		CAN_AFFORD,
		## The node is unlocked and can be interacted with.
		## The player has purchased the maximum level of the upgrade.
		MAXED_OUT
}

@export_category("Event Bus")
@export var main_event_bus: MainEventBus

@export_category("Settings")
@export_group("General")
@export var progress_event_bus: PlayerProgressEventBus
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
@export var skillnode_data : UpgradeData

@export_group("Save Settings")
## A save name for the skillnode_data resource.
@export var save_name: String = ""


@onready var skill_line: Line2D = %SkillBranch
@onready var skill_label_status: Label = %SkillLabel
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
var node_state: NodeState = NodeState.LOCKED
var upgrade_logic: SkillUpgrade

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _enter_tree() -> void:
	if skillnode_data:
		upgrade_logic = SkillUpgrade.new(skillnode_data, next_tier_nodes)
	
	if !upgrade_logic.upgrade_maxed.is_connected(_on_upgrade_maxed) and !upgrade_logic.level_changed.is_connected(_on_level_changed):
		upgrade_logic.upgrade_maxed.connect(_on_upgrade_maxed)
		upgrade_logic.level_changed.connect(_on_level_changed)

func _exit_tree() -> void:
	upgrade_logic.upgrade_maxed.disconnect(_on_upgrade_maxed)
	upgrade_logic.level_changed.disconnect(_on_level_changed)
	main_event_bus.currency_changed.disconnect(_on_currency_changed)
	upgrade_logic.reset_next_tier_nodes_array()
	skillnode_data.reset_next_tier_nodes()

func _ready() -> void:
	if skillnode_data:
		skillnode_data.set_next_tier_nodes(self.next_tier_nodes)
		upgrade_logic = SkillUpgrade.new(skillnode_data, next_tier_nodes)
		upgrade_logic.upgrade_maxed.connect(_on_upgrade_maxed)
		upgrade_logic.level_changed.connect(_on_level_changed)
	
	main_event_bus.currency_changed.connect(_on_currency_changed)
	progress_bar.show()
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
	node_identifier = id
	skillnode_data.set_id(id)

func is_next_tier_unlocked() -> bool:
	return skillnode_data.check_next_tier_unlock(self.next_tier_nodes)

func is_this_skill_maxed_out() -> bool:
	return skillnode_data.check_upgrade_maxed_out()
	
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

func _update_node_state() -> void:
	if !is_unlocked:
		node_state = NodeState.LOCKED
	elif is_maxed_out or skillnode_data.upgrade_level >= skillnode_data.upgrade_max_level:
		node_state = NodeState.MAXED_OUT
		is_maxed_out = true
	elif UpgradeService.can_afford(skillnode_data):
		node_state = NodeState.CAN_AFFORD
	else:
		node_state = NodeState.CANNOT_AFFORD
	_update_cost_background()

func _update_cost_background() -> void:
	cost_background.remove_theme_stylebox_override("panel")
	match node_state:
		NodeState.MAXED_OUT:
			cost_background.add_theme_stylebox_override("panel", max_upgraded_style)
		NodeState.CANNOT_AFFORD:
			cost_background.add_theme_stylebox_override("panel", cannot_afford_style)
		NodeState.CAN_AFFORD:
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

func _on_currency_changed(currency: Constants.CurrencyType) -> void:
	set_currency_icon(currency)
	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(currency))
	_update_node_state()

func set_currency_icon(currency: Constants.CurrencyType) -> void:
	match currency:
		Constants.CurrencyType.BITCOIN:
			currency_icon.texture = bitcoin_icon
		Constants.CurrencyType.FIAT:
			currency_icon.texture = dollar_icon
		_:
			currency_icon.texture = null  # Fallback if an unknown currency is used

#endregion

#region Signals

func _on_mouse_entered() -> void:
	if sound_effect_component_ui == null: return
	sound_effect_component_ui.set_and_play_sound(on_mouse_entered_effect)

func _on_skill_pressed() -> void:
	if not upgrade_logic.purchase():
		return

	_update_skill_node_ui(skillnode_data.upgrade_name, skillnode_data.upgrade_description, skillnode_data.upgrade_cost(UpgradeService.current_currency))
	_update_node_state()

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
		"node_state": node_state,
		"is_unlocked": is_unlocked,
		"is_maxed_out": is_maxed_out
	}

func load_data() -> void:
	var saved_name: String = save_name if !save_name.is_empty() else skillnode_data.upgrade_name
	if !SaveSystem.has(saved_name):
		return
	var data: Dictionary = SaveSystem.get_var(saved_name)
	
	skillnode_data.upgrade_level = data["upgrade_level"]
	node_state = Utils.int_to_skill_node_state(data["node_state"])
	is_maxed_out = data["is_maxed_out"]
	is_unlocked = data["is_unlocked"]
	
	is_next_tier_unlocked()
	is_this_skill_maxed_out()
	
	_update_skill_node_ui(skillnode_data.upgrade_name, \
	skillnode_data.upgrade_description, \
	skillnode_data.upgrade_cost(UpgradeService.current_currency))

	_update_node_state()
	
	_update_skill_status_label("{0}/{1}".format([skillnode_data.upgrade_level, \
	skillnode_data.upgrade_max_level]) if !is_maxed_out else "Maxed")
	
	_update_progress_bar(skillnode_data.upgrade_level, skillnode_data.upgrade_max_level)
	_update_node_line_points()
	
#endregion
