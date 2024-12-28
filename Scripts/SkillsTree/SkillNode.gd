class_name SkillNode extends Button

enum UPGRADE_TYPE {HEALTH, SPEED, DAMAGE}
#enum SKILL_NODE_STATUS {LOCKED, UNLOCKED, MAXED_OUT}

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
@export var upgrade_data : UpgradeData
@export var stat_to_upgrade: PlayerStat
@export var upgrade_type: UPGRADE_TYPE

@export_group("Save Settings")
## A save name for the upgrade_data resource.
@export var save_name: String = ""


@onready var skill_line: Line2D = %SkillBranch
@onready var parent_skill_tree: SkillTreeManager = get_tree().get_first_node_in_group("SkillsTree")
@onready var skill_label_status: Label = %SkillLabel
@onready var skill_info_panel: SkillInfoPanelInNode = $SkillInfoPanel
@onready var animation_component: AnimationComponentUI = $AnimationComponent
@onready var currency_icon: TextureRect = $CurrencyIcon

var is_maxed_out: bool = false
var node_identifier: int = 0
var status: UpgradeData.SKILL_NODE_STATUS = UpgradeData.SKILL_NODE_STATUS.LOCKED

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _enter_tree() -> void:
	upgrade_data.upgrade_maxed.connect(_on_upgrade_maxed)
	upgrade_data.next_tier_unlocked.connect(unlock_next_tier)

func _ready() -> void:
	set_meta("upgrade_type", upgrade_type)
	
	if self.is_unlocked:
		self.upgrade_data.set_upgrade_status(UpgradeData.SKILL_NODE_STATUS.UNLOCKED)
	if upgrade_data.check_next_tier_unlock():
		unlock_next_tier()
	if upgrade_data.check_upgrade_maxed_out():
		_on_upgrade_maxed()
	
	currency_icon.texture = bitcoin_icon if use_bitcoin else dollar_icon

func lock() -> void:
	print_debug("Locked")
	upgrade_data.set_upgrade_status(UpgradeData.SKILL_NODE_STATUS.LOCKED)
	hide()
	#_hide_next_node_line()
	_set_disabled_state(true)
	is_unlocked = false
	_update_skill_status_label("LOCKED", disabled_label_settings)
	_set_modulate_color(Color.GRAY)

func unlock() -> void:
	print_debug("Unlocked")
	self.upgrade_data.set_upgrade_status(UpgradeData.SKILL_NODE_STATUS.UNLOCKED)
	show()
	#_hide_next_node_line()
	_set_disabled_state(false)
	is_unlocked = true
	_update_skill_status_label("{0}/{1}".format([upgrade_data.upgrade_level, upgrade_data.upgrade_max_level]), enabled_label_settings)
	_set_modulate_color(Color.WHITE)

func unlock_next_tier() -> void:
	print("Unlocking next tier nodes...")
	for node in next_tier_nodes:
		if node.is_unlocked:
			continue  # Skip nodes that are already unlocked
		node.unlock()
		print("{0} unlocked".format([node]))

func is_skill_unlocked() -> bool:
	return is_unlocked

func set_upgrade_data(new_data: UpgradeData, type: UPGRADE_TYPE) -> void:
	upgrade_data = new_data
	upgrade_type = type

func set_line_points() -> void:
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

func _on_skill_pressed() -> void:
	if not _buy_upgrade():
		return
	
	_update_skill_status_label("{0}/{1}".format([upgrade_data.upgrade_level, upgrade_data.upgrade_max_level]), enabled_label_settings)
	_update_info_panel(upgrade_data.upgrade_cost())
	_upgrade_stat_on_pressed()

func _upgrade_stat_on_pressed() -> void:
	stat_to_upgrade.value = upgrade_data.apply_upgrade()
	print_debug("The {0} has now the value of {1}".format([stat_to_upgrade.resource_name, stat_to_upgrade.value]))

func _buy_upgrade() -> bool:
	return upgrade_data.buy_upgrade(use_bitcoin)

func _on_upgrade_maxed() -> void:
	upgrade_data.set_upgrade_status(UpgradeData.SKILL_NODE_STATUS.MAXED_OUT)
	print_debug("{0} maxed. Status: {1}".format([upgrade_data.upgrade_name, upgrade_data.status]))
	show()
	#_hide_next_node_line()
	is_maxed_out = true
	#unlock_next_tier()
	_set_disabled_state(true)
	_update_skill_status_label("MAXED")
	_set_modulate_color(Color.GOLD)

func update_ui() -> void:
	self.status = self.upgrade_data.get_upgrade_status()
	match self.status:
		UpgradeData.SKILL_NODE_STATUS.LOCKED:
			hide()
			#_hide_next_node_line()
			_set_disabled_state(true)
			is_unlocked = false
			_update_skill_status_label("LOCKED", disabled_label_settings)
			_set_modulate_color(Color.GRAY)
		UpgradeData.SKILL_NODE_STATUS.UNLOCKED:
			show()
			#_hide_next_node_line()
			_set_disabled_state(false)
			is_unlocked = true
			_update_skill_status_label("{0}/{1}".format([upgrade_data.upgrade_level, upgrade_data.upgrade_max_level]), enabled_label_settings)
			_set_modulate_color(Color.WHITE)
		UpgradeData.SKILL_NODE_STATUS.MAXED_OUT:
			show()
			#_hide_next_node_line()
			unlock_next_tier()
			_set_disabled_state(true)
			_update_skill_status_label("MAXED")
			_set_modulate_color(Color.GOLD)

func _set_disabled_state(state: bool) -> void:
	disabled = state

func _set_modulate_color(color: Color) -> void:
	self_modulate = color

func _update_skill_status_label(new_text, label_settings: LabelSettings = null):
		skill_label_status.text = new_text
		skill_label_status.label_settings = enabled_label_settings
		skill_info_panel.update_cost_label(upgrade_data.upgrade_cost(), true)

func _hide_next_node_line() -> void:
	if next_tier_nodes.size() <= 0: return
	
	await get_tree().process_frame
	
	for node in next_tier_nodes:
		if _is_next_tier_node_unlocked(node.idg):
			node.skill_line.show()
		else:
			node.skill_line.hide()

func _update_info_panel(cost: float) -> void:
	skill_info_panel.update_cost_label(cost, is_maxed_out)

func _is_next_tier_node_unlocked(id_d: int) -> bool:
	for node in next_tier_nodes:
		return node.is_skill_unlocked()
	
	return false

func _on_mouse_entered() -> void:
	skill_info_panel.activate_panel(upgrade_data.upgrade_name, upgrade_data.upgrade_description, upgrade_data.upgrade_cost(), use_bitcoin, is_maxed_out)

func _on_mouse_exited() -> void:
	skill_info_panel.deactivate_panel()

func save_data() -> void:
	print("Data Saved")
	SaveSystem.set_var(save_name if !save_name.is_empty() else upgrade_data.upgrade_name, self.upgrade_data)

func load_data() -> void:
	var saved_name: String = save_name if !save_name.is_empty() else upgrade_data.upgrade_name
	if _is_var_in_saved_dictionary(saved_name) == false:
		print("No data upgrade data found in node {0}".format([self.name]))
		return
	var data = SaveSystem.get_var(saved_name)
	upgrade_data = Utils.build_res_from_dictionary(data, UpgradeData.new())
	
	if upgrade_data.check_next_tier_unlock():
		unlock_next_tier()
	if upgrade_data.check_upgrade_maxed_out():
		_on_upgrade_maxed()
	
	if !is_maxed_out:
		_update_skill_status_label("{0}/{1}".format([upgrade_data.upgrade_level, upgrade_data.upgrade_max_level]), enabled_label_settings)
	
	print("Data Loaded from node {0}".format([self.name]))

func _is_var_in_saved_dictionary(var_name: String) -> bool:
	return SaveSystem.has(var_name)
