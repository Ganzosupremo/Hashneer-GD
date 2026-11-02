class_name SkillTreeView extends Control
## Builds the skill tree from [SkillProgress]: one column per [member SkillDefinition.branch],
## one row per tier, and lines from each skill to its requirements.
##
## Nothing is placed by hand: a new [SkillDefinition] file shows up in its branch on the next run.
## A requirement line lights up once it is met.[br]
## The view lives in the UI layer and scales itself down to fit its parent, so it never moves or zooms.

## Emitted when a node is pressed.
signal skill_selected(skill: SkillDefinition)

## Column order, branches not listed here go after these in alphabetical order.
const BRANCH_ORDER: PackedStringArray = ["Defense", "Offense", "Utility", "Weapons"]

@export var node_scene: PackedScene
@export var node_size: Vector2 = Vector2(64, 64)
## Width of one node slot, a column is as wide as its busiest row.
@export var slot_width: float = 92.0
@export var row_height: float = 82.0
@export var column_gap: float = 14.0
@export var header_height: float = 38.0
@export var line_width: float = 3.0
## Shows the skill name under each node. The name is always in the tooltip and the details panel.
@export var show_node_names: bool = false
## The tree is scaled down to fit its parent, never above this.
@export var max_scale: float = 1.0
@export var line_met_color: Color = Color(1.0, 0.843, 0.0, 0.85)
@export var line_unmet_color: Color = Color(0.45, 0.45, 0.52, 0.55)
@export var column_color: Color = Color(0.04, 0.04, 0.07, 0.55)
@export var column_border_color: Color = Color(1.0, 0.843, 0.0, 0.2)

var _nodes: Dictionary = {}  # StringName id -> SkillTreeNode
var _columns: Array[Dictionary] = []  # {branch, rect}
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

	# branch -> tier -> skills
	var branches: Dictionary = {}
	var max_tier: int = 0
	for skill in skills:
		var tier: int = tiers[skill.id]
		max_tier = maxi(max_tier, tier)
		var by_tier: Dictionary = branches.get_or_add(skill.branch, {})
		by_tier.get_or_add(tier, []).append(skill)

	var height: float = header_height + row_height * (max_tier + 1)
	var x: float = 0.0
	for branch in _sorted_branches(branches.keys()):
		var by_tier: Dictionary = branches[branch]
		var slots: int = 1
		for tier in by_tier:
			slots = maxi(slots, by_tier[tier].size())
		var width: float = slots * slot_width

		for tier in by_tier:
			var row: Array = by_tier[tier]
			var row_start: float = x + (width - row.size() * slot_width) * 0.5
			for i in row.size():
				var center := Vector2(row_start + slot_width * (i + 0.5), header_height + row_height * (tier + 0.5))
				_add_node(row[i], center)

		_add_header(branch, x, width)
		_columns.append({"branch": branch, "rect": Rect2(x, 0.0, width, height)})
		x += width + column_gap

	custom_minimum_size = Vector2(maxf(x - column_gap, 0.0), height)
	size = custom_minimum_size
	queue_redraw()

func _add_node(skill: SkillDefinition, center: Vector2) -> void:
	var node: SkillTreeNode = node_scene.instantiate()
	node.setup(skill)
	add_child(node)
	node.size = node_size
	node.position = center - node_size * 0.5
	node.set_name_visible(show_node_names)
	node.pressed.connect(_on_node_pressed.bind(skill.id))
	_nodes[skill.id] = node

func _add_header(branch: String, x: float, width: float) -> void:
	var label := Label.new()
	label.text = branch.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(x, 0.0)
	label.size = Vector2(width, header_height)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0, 1.0))
	add_child(label)

## Scales the tree down to fit the parent and centers it horizontally.
func _fit_to_parent() -> void:
	var parent_control: Control = get_parent() as Control
	if parent_control == null or custom_minimum_size.x <= 0.0 or custom_minimum_size.y <= 0.0:
		return
	var area: Vector2 = parent_control.size
	var fit: float = minf(minf(area.x / custom_minimum_size.x, area.y / custom_minimum_size.y), max_scale)
	scale = Vector2(fit, fit)
	position = Vector2((area.x - custom_minimum_size.x * fit) * 0.5, 0.0)

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

	for node in _nodes.values():
		for requirement in node.skill.requirements:
			if requirement == null or requirement.skill == null or not _nodes.has(requirement.skill.id):
				continue
			var from: Vector2 = _nodes[requirement.skill.id].get_center()
			var color: Color = line_met_color if requirement.is_met() else line_unmet_color
			draw_line(from, node.get_center(), color, line_width, true)

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
