extends TextureButton
class_name SkillNode

signal skill_node_pressed(skill_node: SkillNode)

@export_category("Skill Node Aesthetics")
@export var active_texture: Texture2D
@export var max_level_texture: Texture2D
@export var disabled_texture: Texture2D

@export_category("Upgrade Data")
@export var upgrade_data : SkillUpgradeData

@onready var skill_line: Line2D = %SkillBranch
@onready var parent_skill_tree: SkillsTree = get_tree().get_first_node_in_group("SkillsTree")

var node_children: Array
var id: int = 0


const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	for children in get_children():
		if children is SkillNode:
			node_children.append(children)
	
	upgrade_data.connect("next_tier_unlocked", unlock_next_tier)
	upgrade_data.connect("upgrade_maxed", on_upgrade_maxed)

	deactivate_children()
	set_aesthetics()
	set_line_points()
	d()

func d() -> void:
	var t = Timer.new()
	add_child(t)
	t.wait_time = 0.15
	t.one_shot = true
	t.start()

	await t.timeout
	if upgrade_data.check_next_tier_unlock():
		unlock_next_tier()
	await get_tree().process_frame
	if upgrade_data.check_upgrade_maxed_out():
		on_upgrade_maxed()

func _enter_tree() -> void:
# for the time being, this function can be called here
# but as the upgrades in the skill tree grow, 
# I need to find another way of loading all the data for each one
	PersistenceDataManager.load_gam()

## deactivates all the children skill nodes
func deactivate_children():
	for child in node_children:
		if child is SkillNode:
			child.disabled = true
			child.texture_normal = disabled_texture

func set_line_points() -> void:
	if not get_parent() is SkillNode: return

	skill_line.clear_points()
	
	# Calculate the center of the current node in global coordinates
	var current_node_center_global = global_position + self.get_global_rect().size / 2
	# Calculate the center of the parent node in global coordinates
	var parent_node_center_global = get_parent().global_position + get_parent().get_global_rect().size / 2

	# Convert global positions to local positions relative to the Line2D node
	var current_node_center_local = skill_line.to_local(current_node_center_global)
	var parent_node_center_local = skill_line.to_local(parent_node_center_global)
	
	skill_line.add_point(current_node_center_local)
	skill_line.add_point(parent_node_center_local)

func set_aesthetics() -> void:
	texture_normal = active_texture
	
	if disabled == true: 
		texture_pressed = disabled_texture
		texture_focused = disabled_texture		
	else: 
		texture_focused = active_texture
		texture_pressed = active_texture
		
	texture_disabled = disabled_texture

func _on_pressed() -> void:
	parent_skill_tree.show_skill_info_window(upgrade_data)

func unlock_next_tier() -> void:
	for child in get_children():
		if child is SkillNode:
			child.texture_normal = child.active_texture
			child.texture_pressed = child.active_texture
			child.texture_focused = child.active_texture
			child.upgrade_data.is_unlocked = true
			child.disabled = false

func on_upgrade_maxed() -> void:
	texture_normal = max_level_texture
	texture_pressed = max_level_texture
	texture_focused = max_level_texture

func merge_upgrades():
	UpgradesManager.upgrades.merge(upgrade_data.build_skill_dictionary())
 
func save_data() -> void:
	SaveSystem.set_var(self.upgrade_data.upgrade_name, self.upgrade_data)

func load_data() -> void:
	if SaveSystem.has(self.upgrade_data.upgrade_name):
		var data = SaveSystem.get_var(self.upgrade_data.upgrade_name)
		upgrade_data = build_res(data)
		upgrade_data.upgrade_level = data["upgrade_level"]
	
		if upgrade_data.check_next_tier_unlock():
			unlock_next_tier()
		if upgrade_data.check_upgrade_maxed_out():
			on_upgrade_maxed()

func build_res(data: Dictionary) -> SkillUpgradeData:
	var res: SkillUpgradeData = SkillUpgradeData.new()
	for i in range(data.size()):
		var key = data.keys()[i]
		var value = data.values()[i]
		res.set(key, value)
	return res
