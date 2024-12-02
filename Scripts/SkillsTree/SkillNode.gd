class_name SkillNode extends Button

enum UPGRADE_TYPE {HEALTH, SPEED, DAMAGE}

@export_category("General Settings")
@export var use_bitcoin: bool = false

@export var is_unlocked: bool = false
@export var next_tier_nodes: Array[SkillNode]

@export_group("UI Label Settings")
## This settings will be used when the skill node is active.
@export var enabled_label_settings: LabelSettings
## This settings will be used when the skill node is locked i.e disabled.
@export var disabled_label_settings: LabelSettings


@export_group("Upgrade Data")
@export var upgrade_data : UpgradeData
@export var resource_to_upgrade: Resource
@export var upgrade_type: UPGRADE_TYPE


@onready var skill_line: Line2D = %SkillBranch
@onready var parent_skill_tree: SkillTreeManager = get_tree().get_first_node_in_group("SkillsTree")
@onready var skill_label_status: Label = %SkillLabel
@onready var skill_info_panel: SkillInfoPanelInNode = $SkillInfoPanel
@onready var animation_component: AnimationComponentUI = $AnimationComponent

var node_children: Array
var id: int = 0

func _enter_tree() -> void:
	upgrade_data.upgrade_maxed.connect(_on_upgrade_maxed)
	upgrade_data.next_tier_unlocked.connect(unlock_next_tier)


func _exit_tree() -> void:
	upgrade_data.upgrade_maxed.disconnect(_on_upgrade_maxed)
	upgrade_data.next_tier_unlocked.disconnect(unlock_next_tier)

func _ready() -> void:
	set_meta("upgrade_type", upgrade_type)
	#_toggle_skill_node()
	update_ui()

## deactivates all the children skill nodes
func lock() -> void:
	print_debug("Locked")
	is_unlocked = false
	disabled = true
	update_ui()

func unlock() -> void:
	print_debug("Unlocked")
	is_unlocked = true
	disabled = false
	update_ui()

## Sets the var to save in the skill tree, used by the skill tree
func set_var_to_save() -> void:
	print("Data Saved")
	SaveSystem.set_var(self.upgrade_data.resource_name, self.upgrade_data)

## Gets the var to load in the skill tree, used by the skill tree
func get_var_to_load() -> void:
	if SaveSystem.has(self.upgrade_data.resource_name):
		var data = SaveSystem.get_var(self.upgrade_data.resource_name)

		upgrade_data = Utils.build_res_from_dictionary(data, UpgradeData.new())

		if upgrade_data.can_update_status():
			update_ui()
			_toggle_skill_node()
		print("Data Loaded")


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


func _on_skill_pressed(upgrade_type: UPGRADE_TYPE, upgrade_actions: Dictionary) -> void:
	if not _buy_upgrade():
		#_tween_button_on_failed_purchase()
		return
		
	if upgrade_type in upgrade_actions:
		upgrade_actions[upgrade_type].call(resource_to_upgrade)
		update_ui()  # Update your UI to reflect changes
		_update_info_panel(upgrade_data.upgrade_name, upgrade_data.upgrade_description, upgrade_data.upgrade_cost_string())
		print("Upgraded:", upgrade_type)
	else:
		print("Invalid upgrade type:", upgrade_type)

func _on_pressed() -> void:
	print("Button Clicked")
	if !_buy_upgrade():
		_tween_button_on_failed_purchase()
		return
	if !resource_to_upgrade: return
	
	print("Upgrade Bought")
	update_ui()

func _buy_upgrade() -> bool:
	return upgrade_data.buy_upgrade(use_bitcoin)

func _tween_button_on_failed_purchase() -> void:
	animation_component.shake_tween()

func unlock_next_tier() -> void:
	print("Upgrade Maxed Out")
	for node in next_tier_nodes:
		node.is_unlocked = true
		node.update_ui()
	self._toggle_skill_node()
	self.disabled = true

func _toggle_skill_node() -> void:
	if is_unlocked:
		show()
		_hide_next_node_line()
	else:
		hide()
		_hide_next_node_line()

func update_ui() -> void:
	if is_unlocked:
		show()
		_hide_next_node_line()
		disabled = false
		if skill_label_status != null:
			skill_label_status.text = "{0}/{1}".format([upgrade_data.upgrade_level, upgrade_data.upgrade_max_level])
			skill_label_status.label_settings = enabled_label_settings
		self_modulate = Color.WHITE
	else:
		hide()
		_hide_next_node_line()
		disabled = true
		if skill_label_status != null: 
			skill_label_status.text = "LOCKED"
			skill_label_status.label_settings = disabled_label_settings
		self_modulate = Color.GRAY

func _hide_next_node_line() -> void:
	if next_tier_nodes.size() <= 0: return
	
	await get_tree().process_frame
	
	for node in next_tier_nodes:
		if _is_next_tier_node_unlocked(node.id):
			node.skill_line.show()
		else:
			node.skill_line.hide()

func _update_info_panel(title: String, description: String, cost: String) -> void:
	skill_info_panel.toggle_panel(title, description, cost)

func _is_next_tier_node_unlocked(id: int) -> bool:
	return next_tier_nodes[id].is_skill_unlocked()

func _on_upgrade_maxed() -> void:
	update_ui()
	disabled = true

func _on_mouse_entered() -> void:
	skill_info_panel.activate_panel(upgrade_data.upgrade_name, upgrade_data.upgrade_description, upgrade_data.upgrade_cost_string(), use_bitcoin)

func _on_mouse_exited() -> void:
	skill_info_panel.deactivate_panel()
