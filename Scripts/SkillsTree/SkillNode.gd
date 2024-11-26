class_name SkillNode extends Button

enum UPGRADE_TYPE {HEALTH, SPEED, DAMAGE}


@export_category("Currency To Use")
@export var use_bitcoin: bool = false

@export_category("UI Variables")
@export var upgrade_name: String = ""
@export_multiline var upgrade_descripion: String = ""
@export var is_unlocked: bool = false
@export var next_tier_nodes: Array[SkillNode]

@export_group("UI Label Settings")
## This settings will be used when the skill node is active.
@export var enabled_label_settings: LabelSettings
## This settings will be used when the skill node is locked i.e disabled.
@export var disabled_label_settings: LabelSettings

@export_category("Skill Node Aesthetics")
@export var active_texture: Texture2D
@export var max_level_texture: Texture2D
@export var disabled_texture: Texture2D

@export_category("Upgrade Data")
@export var upgrade_data : UpgradeData
@export var resource_to_upgrade: Resource
@export var upgrade_type: UPGRADE_TYPE


@onready var skill_line: Line2D = %SkillBranch
@onready var parent_skill_tree: SkillTreeManager = get_tree().get_first_node_in_group("SkillsTree")
@onready var skill_label_status: Label = %SkillLabel
@onready var skill_info_panel: SkillInfoPanelInNode = $SkillInfoPanel


var node_children: Array
var id: int = 0

#func _ready() -> void:
	#update_ui()
	#for children in get_children():
		#if children is SkillNode:
			#node_children.append(children)
	#upgrade_data.connect("next_tier_unlocked", unlock_next_tier)
	#upgrade_data.connect("upgrade_maxed", on_upgrade_maxed)
	#text = upgrade_data.upgrade_name
	#print("D ", upgrade_data.upgrade_name)
	#deactivate_children()
	#set_aesthetics()
	#set_line_points()

func _enter_tree() -> void:
# for the time being, this function can be called here
# but as the upgrades in the skill tree grow, 
# I need to find another way of loading all the data for each one
	upgrade_data.upgrade_maxed.connect(_on_upgrade_maxed)
	upgrade_data.next_tier_unlocked.connect(unlock_next_tier)
	#PersistenceDataManager.load_game()

func _exit_tree() -> void:
	upgrade_data.upgrade_maxed.disconnect(_on_upgrade_maxed)
	upgrade_data.next_tier_unlocked.disconnect(unlock_next_tier)

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

# Sets the var to save in the skill tree, used by the skill tree
func set_var_to_save() -> void:
	print("Data Saved")
	SaveSystem.set_var(self.upgrade_data.resource_name, self.upgrade_data)

# Gets the var to load in the skill tree, used by the skill tree
func get_var_to_load() -> void:
	if SaveSystem.has(self.upgrade_data.resource_name):
		var data = SaveSystem.get_var(self.upgrade_data.resource_name)

		upgrade_data = Utils.build_res_from_dictionary(data, UpgradeData.new())

		if upgrade_data.can_update_status():
			update_ui()
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

func _on_pressed() -> void:
	print("Button Clicked")
	if !_buy_upgrade(): return
	if !resource_to_upgrade: return
	
	print("Upgrade Bought")
	update_ui()
	
	match upgrade_type:
		UPGRADE_TYPE.HEALTH:
			resource_to_upgrade.max_health += upgrade_data.apply_upgrade()
		UPGRADE_TYPE.SPEED:
			resource_to_upgrade.speed += upgrade_data.apply_upgrade()
		UPGRADE_TYPE.DAMAGE:
			pass


func _buy_upgrade() -> bool:
	return upgrade_data.buy_upgrade(use_bitcoin)

func _tween_button_on_failed_purchase() -> void:
	var tween: Tween = get_tree().create_tween().set_ease(Tween.EASE_IN_OUT).set_speed_scale(1.2)
	


func unlock_next_tier() -> void:
	print("Upgrade Maxed Out")
	for node in next_tier_nodes:
		node.is_unlocked = true
		node.update_ui()
	self.update_ui()
	self.disabled = true
	
	#for child in get_children():
		#if child is SkillNode:
			#child.texture_normal = child.active_texture
			#child.texture_pressed = child.active_texture
			#child.texture_focused = child.active_texture
			#child.upgrade_data.is_unlocked = true
			#child.disabled = false

func update_ui() -> void:
	if is_unlocked:
		show()
		_hide_next_node_line()
		#skill_line.show()
		disabled = false
		if skill_label_status != null:
			skill_label_status.text = "{0}/{1}".format([upgrade_data.upgrade_level, upgrade_data.upgrade_max_level])
			skill_label_status.label_settings = enabled_label_settings
		self_modulate = Color.WHITE
	else:
		hide()
		_hide_next_node_line()
		#skill_line.hide()
		disabled = true
		if skill_label_status != null: 
			skill_label_status.text = "LOCKED"
			skill_label_status.label_settings = disabled_label_settings
		self_modulate = Color.GRAY

func _hide_next_node_line() -> void:
	for i in range(next_tier_nodes.size()):
		if _is_next_tier_node_unlocked(i):
			next_tier_nodes[i].skill_line.show()
		else:
			next_tier_nodes[i].skill_line.hide()

func update_info_panel(title: String, description: String, cost: String) -> void:
	skill_info_panel.activate_panel(title, description, cost)

func _is_next_tier_node_unlocked(id: int) -> bool:
	return next_tier_nodes[id].is_skill_unlocked()

func _on_upgrade_maxed() -> void:
	text = "STAT MAX UPGRADED"
	update_ui()
	disabled = true



func _on_mouse_entered() -> void:
	update_info_panel(upgrade_data.upgrade_name, upgrade_data.upgrade_description, upgrade_data.upgrade_cost_string())


func _on_mouse_exited() -> void:
	update_info_panel("","", "")
	skill_info_panel.deactivate_panel()
