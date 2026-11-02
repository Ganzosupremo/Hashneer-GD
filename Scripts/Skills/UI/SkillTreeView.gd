class_name SkillTreeView extends Control
## Builds the skill tree from [SkillProgress]: one column per [member SkillDefinition.branch],
## each laid out as a grid in tier order.
##
## Nothing is placed by hand: a new [SkillDefinition] file shows up in its branch on the next run.
## The view lives in the UI layer and picks the grid shape that fills its parent best, so it never
## moves or zooms. Locked skills show it on the node, their requirements are in the details panel.

## Emitted when a node is pressed.
signal skill_selected(skill: SkillDefinition)

## Column order, branches not listed here go after these in alphabetical order.
const BRANCH_ORDER: PackedStringArray = ["Defense", "Offense", "Utility", "Weapons"]

@export var node_scene: PackedScene
@export var node_size: Vector2 = Vector2(76, 76)
## Width of one node slot, a column is as wide as its busiest row.
@export var slot_width: float = 100.0
@export var row_height: float = 92.0
@export var column_gap: float = 14.0
@export var header_height: float = 38.0
## Shows the skill name under each node. The name is always in the tooltip and the details panel.
@export var show_node_names: bool = false
## The tree is scaled to fill its parent, never above this.
@export var max_scale: float = 2.0
@export var column_color: Color = Color(0.04, 0.04, 0.07, 0.55)
@export var column_border_color: Color = Color(1.0, 0.843, 0.0, 0.2)

var _nodes: Dictionary = {}  # StringName id -> SkillTreeNode
var _columns: Array[Dictionary] = []  # {branch, rect}
var _branch_order: Array = []
var _branch_skills: Dictionary = {}  # branch -> Array of skills, in tier order
var _headers: Dictionary = {}  # branch -> Label
var _selected_id: StringName = &""
var _mode_filter: int = 0


func _ready() -> void:
	_build()
	var parent_control: Control = get_parent() as Control
	if parent_control:
		parent_control.resized.connect(_fit_to_parent)
	_fit_to_parent.call_deferred()
	SkillProgress.skill_changed.connect(_on_skill_changed)
	SkillProgress.progress_reset.connect(refresh)
	SkillProgress.costs_changed.connect(refresh)
	BitcoinWallet.money_changed.connect(_on_money_changed)

func _exit_tree() -> void:
	SkillProgress.skill_changed.disconnect(_on_skill_changed)
	SkillProgress.progress_reset.disconnect(refresh)
	SkillProgress.costs_changed.disconnect(refresh)
	BitcoinWallet.money_changed.disconnect(_on_money_changed)

#region Public API

func refresh() -> void:
	for node in _nodes.values():
		node.refresh()
	queue_redraw()

## Fades the skills that don't work in [param mode], 0 shows every skill normally.
func set_mode_filter(mode: int) -> void:
	_mode_filter = mode
	for node in _nodes.values():
		node.set_dimmed(not node.skill.applies_in(mode))

func select_skill(skill_id: StringName) -> void:
	if _nodes.has(_selected_id):
		_nodes[_selected_id].set_selected(false)
	_selected_id = skill_id
	if _nodes.has(skill_id):
		_nodes[skill_id].set_selected(true)
		skill_selected.emit(_nodes[skill_id].skill)

func get_node_for(skill_id: StringName) -> SkillTreeNode:
	return _nodes.get(skill_id, null)

#endregion

#region Layout

func _build() -> void:
	var skills: Array[SkillDefinition] = SkillProgress.get_all_skills()
	var tiers: Dictionary = {}
	for skill in skills:
		_get_tier(skill, tiers, [])

	# Inside a branch the skills go in tier order, so the cheap ones come first
	var branches: Dictionary = {}  # branch -> Array of skills
	for skill in skills:
		branches.get_or_add(skill.branch, []).append(skill)
	_branch_order = _sorted_branches(branches.keys())
	for branch in _branch_order:
		var list: Array = branches[branch]
		list.sort_custom(func(a: SkillDefinition, b: SkillDefinition) -> bool:
			if tiers[a.id] != tiers[b.id]:
				return tiers[a.id] < tiers[b.id]
			return String(a.id) < String(b.id))
		_branch_skills[branch] = list
		for skill in list:
			_add_node(skill)
		_headers[branch] = _add_header(branch)

## Places every branch as a grid of [param rows] rows (wider when it has more skills)
## and returns the size of the whole tree.
func _layout(rows: int) -> Vector2:
	_columns.clear()
	var x: float = 0.0
	for branch in _branch_order:
		var list: Array = _branch_skills[branch]
		var cols: int = maxi(ceili(float(list.size()) / rows), 1)
		var width: float = cols * slot_width
		for i in list.size():
			var center := Vector2(x + slot_width * (i % cols + 0.5), header_height + row_height * (floori(float(i) / cols) + 0.5))
			var node: SkillTreeNode = _nodes[list[i].id]
			node.position = center - node_size * 0.5
		var header: Label = _headers[branch]
		header.position = Vector2(x, 0.0)
		header.size = Vector2(width, header_height)
		_columns.append({"branch": branch, "rect": Rect2(x, 0.0, width, header_height + row_height * rows)})
		x += width + column_gap
	return Vector2(maxf(x - column_gap, 0.0), header_height + row_height * rows)

## Most skills in one branch, the most rows a layout can need.
func _get_max_branch_size() -> int:
	var most: int = 1
	for branch in _branch_order:
		most = maxi(most, _branch_skills[branch].size())
	return most

func _add_node(skill: SkillDefinition) -> void:
	var node: SkillTreeNode = node_scene.instantiate()
	node.setup(skill)
	add_child(node)
	node.size = node_size
	node.set_name_visible(show_node_names)
	node.pressed.connect(_on_node_pressed.bind(skill.id))
	_nodes[skill.id] = node

func _add_header(branch: String) -> Label:
	var label := Label.new()
	label.text = branch.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0, 1.0))
	add_child(label)
	return label

## Picks the number of rows that lets the tree be the biggest in the parent, then scales it to fit
## and centers it. Runs again when the parent is resized.
func _fit_to_parent() -> void:
	var parent_control: Control = get_parent() as Control
	if parent_control == null or _branch_order.is_empty():
		return
	var area: Vector2 = parent_control.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	var best_rows: int = 1
	var best_fit: float = 0.0
	for rows in range(1, _get_max_branch_size() + 1):
		var content: Vector2 = _layout(rows)
		var fit: float = minf(area.x / content.x, area.y / content.y)
		if fit > best_fit + 0.001:
			best_fit = fit
			best_rows = rows
	var tree_size: Vector2 = _layout(best_rows)
	var fit: float = minf(best_fit, max_scale)
	custom_minimum_size = tree_size
	size = tree_size
	scale = Vector2(fit, fit)
	position = Vector2((area.x - tree_size.x * fit) * 0.5, (area.y - tree_size.y * fit) * 0.5)
	queue_redraw()

## Row of a skill: [member SkillDefinition.tier] if set, otherwise one below its deepest requirement.
func _get_tier(skill: SkillDefinition, cache: Dictionary, visiting: Array) -> int:
	if cache.has(skill.id):
		return cache[skill.id]
	var tier: int = 0
	if skill.tier >= 0:
		tier = skill.tier
	elif not visiting.has(skill.id):
		visiting.append(skill.id)
		for requirement in skill.requirements:
			if requirement and requirement.skill:
				tier = maxi(tier, _get_tier(requirement.skill, cache, visiting) + 1)
		visiting.erase(skill.id)
	else:
		push_warning("SkillTreeView: requirement loop through '%s'" % skill.id)
	cache[skill.id] = tier
	return tier

func _sorted_branches(names: Array) -> Array:
	var ordered: Array = []
	for branch in BRANCH_ORDER:
		if names.has(branch):
			ordered.append(branch)
	var others: Array = names.filter(func(branch) -> bool: return not BRANCH_ORDER.has(branch))
	others.sort()
	ordered.append_array(others)
	return ordered

#endregion

#region Drawing

func _draw() -> void:
	var column_box := StyleBoxFlat.new()
	column_box.bg_color = column_color
	column_box.border_color = column_border_color
	column_box.set_border_width_all(2)
	column_box.set_corner_radius_all(18)
	for column in _columns:
		draw_style_box(column_box, column.rect.grow(10.0))


#endregion

#region Signals

func _on_node_pressed(skill_id: StringName) -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	select_skill(skill_id)

func _on_skill_changed(_skill_id: StringName, _level: int) -> void:
	refresh()

func _on_money_changed(_amount: float, _currency: Constants.CurrencyType) -> void:
	refresh()

#endregion
