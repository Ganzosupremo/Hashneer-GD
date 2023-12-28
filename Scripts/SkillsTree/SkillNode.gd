extends TextureButton
class_name SkillNode

signal skill_node_pressed(skill_node: SkillNode)

@export_category("Skill Node Aesthetics")
@export var disabled_color: Color
@export var active_color: Color

@export var active_texture: Texture2D
@export var max_level_texture: Texture2D
@export var disabled_texture: Texture2D

@export_category("Upgrade Data")
@export var upgrade_data : SkillUpgradeData

@onready var skill_line: Line2D = %SkillBranch
@onready var parent_skill_tree: SkillsTree = get_tree().get_first_node_in_group("SkillsTree")

var node_children: Array
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]
func _ready() -> void:
	for children in get_children():
		if children is SkillNode:
			node_children.append(children)
	
	upgrade_data.connect("next_tier_unlocked", unlock_next_tier)
	upgrade_data.connect("upgrade_maxed", on_upgrade_maxed)
	
	merge_upgrades()
	deactivate_children()
	set_aesthetics()
	set_line_points()

## deactivates all the children skill nodes
func deactivate_children():
	for child in node_children:
		if child is SkillNode:
			child.disabled = true
#			child.visible = false
			child.texture_normal = disabled_texture

func set_line_points():
	if not get_parent() is SkillNode:
		return

	skill_line.clear_points()
	# Calculate the center of the current node
	var current_node_center = self.global_position + self.get_rect().size / 2
	# Calculate the center of the parent node
	var parent_node_center = get_parent().global_position + get_parent().get_rect().size / 2
	
	skill_line.add_point(current_node_center)
	skill_line.add_point(parent_node_center)

func set_aesthetics():
	texture_normal = active_texture
	
	if disabled == true: texture_pressed = disabled_texture
	else: texture_pressed = active_texture
	
	if disabled == true: texture_focused = disabled_texture
	else: texture_focused = active_texture
	
	texture_disabled = disabled_texture

func _on_pressed() -> void:
	parent_skill_tree.show_skill_info_window(upgrade_data)

func unlock_next_tier():
	for child in get_children():
		if child is SkillNode:
			child.texture_normal = child.active_texture
			child.texture_pressed = child.active_texture
			child.texture_focused = child.active_texture
			child.disabled = false
			child.visible = true

func on_upgrade_maxed():
	texture_normal = max_level_texture
	texture_pressed = max_level_texture
	texture_focused = max_level_texture

func merge_upgrades():
	UpgradesManager.upgrades.merge(upgrade_data.build_skill_dictionary())

func save() -> Dictionary:
	return {
#		"filename" : get_scene_file_path(),
#		"parent" : get_parent().get_path(),
		"id": upgrade_data.id,
		"level": upgrade_data.upgrade_level,
		"power": upgrade_data.upgrade_power(),
		"current cost": upgrade_data.upgrade_cost()
	}
 
func save_data(data: GameData) -> void:
	data.skill_node_data.upgrades_data.merge(save())

func load_data(data: GameData) -> void:
	if upgrade_data.id == data.data["skill_node_data"]["id"]:
		self.upgrade_data.upgrade_level = data.skill_node_data.data[upgrade_data.id]["level"]
