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
		
	deactivate_children()
	set_aesthetics()
	set_line_points()

func deactivate_children():
	for child in node_children:
		if child is SkillNode:
			child.disabled = true

func set_line_points():
#	if get_parent() is SkillNode:
	skill_line.clear_points()
	skill_line.add_point(self.global_position + self.size/2)
	skill_line.add_point(get_parent().global_position + get_parent().size/2)
	print("line added [Node: %s]" % name)

func set_aesthetics():
	texture_normal = normal_texture
	texture_pressed = pressed_texture
	texture_focused = focused_texture
	self_modulate = disabled_color
	
	skill_line.texture = line_disable_texture

func _on_pressed() -> void:
	self_modulate = active_color
	skill_line.texture = line_active_texture
	parent_skill_tree.show_skill_info_window(self)

func unlock_next_tier():
	for child in node_children:
		if child is SkillNode:
			child.self_modulate = active_color
			child.disabled = false
