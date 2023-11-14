extends TextureButton
class_name SkillNode

signal skill_node_pressed(skill_node: SkillNode)

@export_category("Skill Node Aesthetics")
@export var disabled_color: Color
@export var active_color: Color
@export var normal_texture: Texture2D
@export var pressed_texture: Texture2D
@export var focused_texture: Texture2D

@export_category("Skill Line Aesthetics")
@export var line_active_texture: Texture2D
@export var line_disable_texture: Texture2D

@export_category("Skill Node Data")
@export var upgrade_data : UpgradeBase

@onready var skill_line: Line2D
@onready var parent_skill_tree: SkillsTree = get_tree().get_first_node_in_group("SkillsTree")

var node_children: Array

func _ready() -> void:
	skill_line = get_node("SkillBranch") as Line2D
	node_children = get_children()
	upgrade_data.connect("next_tier_unlocked", Callable(self, "unlock_next_tier"))
	
	set_aesthetics()
	deactivate_children()
	set_line_points()

func deactivate_children():
	for child in node_children:
		if child is SkillNode:
			child.disabled = true
			child.self_modulate = disabled_color

func set_line_points():
	if not get_parent() is SkillNode:
		return

	skill_line.clear_points()
	# Calculate the center of the current node
	var current_node_center = self.global_position + self.get_rect().size / 2
	# Calculate the center of the parent node
	var parent_node_center = get_parent().global_position + get_parent().get_rect().size / 2

	print("Node ", name + " global position: ", global_position)
	print(name + " Center: ", current_node_center)
	print(name + "Parent Center: ", parent_node_center)

	skill_line.add_point(current_node_center)
	skill_line.add_point(parent_node_center)

func set_aesthetics():
	texture_normal = normal_texture
	texture_pressed = pressed_texture
	texture_focused = focused_texture
	self_modulate = active_color

func _on_pressed() -> void:
	self_modulate = active_color
	skill_line.texture = line_active_texture
	parent_skill_tree.show_skill_info_window(self)

func unlock_next_tier():
	for child in node_children:
		if child is SkillNode:
			child.self_modulate = active_color
			child.disabled = false

func save() -> Dictionary:
	return {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"upgrade_data": {
			"level": upgrade_data.upgrade_level,
			"power": upgrade_data.upgrade_power(),
			"cost": upgrade_data.upgrade_cost()
		}
	}

