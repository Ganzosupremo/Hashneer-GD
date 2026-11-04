class_name SkillTreeView extends VBoxContainer
## Builds the skill tree from [SkillProgress]: one tab per [member SkillDefinition.branch], and inside
## the tab one row per tier.
##
## Nothing is placed by hand: a new [SkillDefinition] file shows up in its branch on the next run, and
## a new branch name becomes a new tab. Nodes keep their size no matter how many skills there are,
## when a branch doesn't fit the area it scrolls vertically.
## The static layout lives in [code]Scenes/SkillTreeSystem/SkillTreeView.tscn[/code].

## Emitted when a node is pressed.
signal skill_selected(skill: SkillDefinition)

## Tab order, branches not listed here go after these in alphabetical order.
const BRANCH_ORDER: PackedStringArray = ["Defense", "Offense", "Utility", "Weapons"]
const HEADER_COLOR: Color = Color(1.0, 0.843, 0.0, 1.0)
const CAN_BUY_COLOR: Color = Color(0.3, 0.9, 0.45, 1.0)

@export var node_scene: PackedScene
@export var node_size: Vector2 = Vector2(76, 76)
@export var node_gap: int = 12
## Width of the tier label on the left of each row.
@export var tier_label_width: float = 44.0
## Shows the skill name under each node. The name is always in the tooltip and the details panel.
@export var show_node_names: bool = false

## Tab that was open last time, so coming back from a run opens the same branch.
static var _last_branch: String = ""

@onready var _branch_tabs: HFlowContainer = %BranchTabs
@onready var _can_buy_filter: Button = %CanBuyFilter
@onready var _mode_filter_button: OptionButton = %ModeFilter
@onready var _scroll: ScrollContainer = %Scroll
@onready var _tier_rows: VBoxContainer = %TierRows
@onready var _empty_label: Label = %EmptyLabel

var _nodes: Dictionary = {}  # StringName id -> SkillTreeNode
var _branch_order: Array = []
var _branch_tiers: Dictionary = {}  # branch -> Array of {tier: int, skills: Array}
var _tabs: Dictionary = {}  # branch -> Button
var _tab_dots: Dictionary = {}  # branch -> Control
var _rows: Array[Dictionary] = []  # rows of the open branch: {row: Control, nodes: Array}
var _current_branch: String = ""
var _selected_id: StringName = &""
var _mode_filter: int = 0


func _ready() -> void:
	_build()
	_style_scroll_bar()
	_can_buy_filter.toggled.connect(_on_can_buy_toggled)
	_mode_filter_button.item_selected.connect(_on_mode_filter_selected)
	var start: String = _last_branch if _branch_order.has(_last_branch) else ""
	if start.is_empty() and not _branch_order.is_empty():
		start = _branch_order[0]
	if not start.is_empty():
		show_branch(start)
	SkillProgress.skill_changed.connect(_on_skill_changed)
	SkillProgress.progress_reset.connect(refresh)
	SkillProgress.costs_changed.connect(refresh)
	BitcoinWallet.money_changed.connect(_on_money_changed)

func _exit_tree() -> void:
	SkillProgress.skill_changed.disconnect(_on_skill_changed)
	SkillProgress.progress_reset.disconnect(refresh)
	SkillProgress.costs_changed.disconnect(refresh)
	BitcoinWallet.money_changed.disconnect(_on_money_changed)
	# Nodes of the closed tabs are not in the tree, free them with the view
	for node in _nodes.values():
		if is_instance_valid(node) and not node.is_inside_tree():
			node.queue_free()

#region Public API

func refresh() -> void:
	for node in _nodes.values():
		node.refresh()
	_update_tab_dots()
	_apply_filters()

## Fades the skills that don't work in [param mode], 0 shows every skill normally.
func set_mode_filter(mode: int) -> void:
	_mode_filter = mode
	for node in _nodes.values():
		node.set_dimmed(not node.skill.applies_in(mode))

# Item ids of the ModeFilter option button
func _on_mode_filter_selected(index: int) -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	match _mode_filter_button.get_item_id(index):
		1: set_mode_filter(Constants.GameModeFlag.MINING)
		2: set_mode_filter(Constants.GameModeFlag.WAVES)
		_: set_mode_filter(0)

## Selects a skill and opens its branch if another one is open.
func select_skill(skill_id: StringName) -> void:
	if _nodes.has(_selected_id):
		_nodes[_selected_id].set_selected(false)
	_selected_id = skill_id
	if _nodes.has(skill_id):
		var node: SkillTreeNode = _nodes[skill_id]
		if node.skill.branch != _current_branch:
			show_branch(node.skill.branch)
		node.set_selected(true)
		_scroll.ensure_control_visible.call_deferred(node)
		skill_selected.emit(node.skill)

func get_node_for(skill_id: StringName) -> SkillTreeNode:
	return _nodes.get(skill_id, null)

## Opens the tab of [param branch].
func show_branch(branch: String) -> void:
	if not _branch_tiers.has(branch):
		return
	_current_branch = branch
	_last_branch = branch
	# button_pressed (not set_pressed_no_signal) so the ButtonGroup releases the other tabs.
	# It only emits toggled, the tabs listen to pressed, so this doesn't call show_branch again.
	_tabs[branch].button_pressed = true
	for child in _tier_rows.get_children():
		for node in _get_row_nodes(child):
			node.get_parent().remove_child(node)
		_tier_rows.remove_child(child)
		child.queue_free()
	_rows.clear()
	var tier_list: Array = _branch_tiers[branch]
	for i in tier_list.size():
		_add_tier_row(i, tier_list[i].skills)
	_scroll.scroll_vertical = 0
	_apply_filters()

#endregion

#region Build

## Wider, gold scroll bar so it is clear the branch has more rows below.
func _style_scroll_bar() -> void:
	var bar: VScrollBar = _scroll.get_v_scroll_bar()
	bar.custom_minimum_size.x = 10.0
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	track.set_corner_radius_all(5)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(HEADER_COLOR, 0.6)
	grabber.set_corner_radius_all(5)
	var grabber_hover := StyleBoxFlat.new()
	grabber_hover.bg_color = HEADER_COLOR
	grabber_hover.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", grabber)
	bar.add_theme_stylebox_override("grabber_highlight", grabber_hover)
	bar.add_theme_stylebox_override("grabber_pressed", grabber_hover)

func _build() -> void:
	var skills: Array[SkillDefinition] = SkillProgress.get_all_skills()
	var tiers: Dictionary = {}
	for skill in skills:
		_get_tier(skill, tiers, [])

	var branches: Dictionary = {}  # branch -> {tier -> Array of skills}
	for skill in skills:
		var by_tier: Dictionary = branches.get_or_add(skill.branch, {})
		by_tier.get_or_add(tiers[skill.id], []).append(skill)
		_add_node(skill)

	_branch_order = _sorted_branches(branches.keys())
	var group := ButtonGroup.new()
	for branch in _branch_order:
		var tier_list: Array = []
		var tier_numbers: Array = branches[branch].keys()
		tier_numbers.sort()
		for tier in tier_numbers:
			var list: Array = branches[branch][tier]
			list.sort_custom(func(a: SkillDefinition, b: SkillDefinition) -> bool: return String(a.id) < String(b.id))
			tier_list.append({"tier": tier, "skills": list})
		_branch_tiers[branch] = tier_list
		_add_tab(branch, group)
	_update_tab_dots()

## Nodes are created once and moved in and out of the rows when the tab changes.
func _add_node(skill: SkillDefinition) -> void:
	var node: SkillTreeNode = node_scene.instantiate()
	node.setup(skill)
	node.custom_minimum_size = node_size
	# PASS lets the mouse wheel reach the ScrollContainer while the cursor is over a node
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	node.pressed.connect(_on_node_pressed.bind(skill.id))
	_nodes[skill.id] = node
	# Runs _ready so refresh() works while the node is in no tab
	add_child(node)
	node.set_name_visible(show_node_names)
	remove_child(node)

func _add_tab(branch: String, group: ButtonGroup) -> void:
	var tab := Button.new()
	tab.text = branch.to_upper()
	tab.toggle_mode = true
	tab.button_group = group
	tab.focus_mode = Control.FOCUS_NONE
	tab.custom_minimum_size = Vector2(0, 34)
	tab.add_theme_font_size_override("font_size", 14)
	tab.pressed.connect(_on_tab_pressed.bind(branch))
	_branch_tabs.add_child(tab)
	_tabs[branch] = tab

	# Green dot in the corner when something in the branch can be bought
	var dot := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = CAN_BUY_COLOR
	box.set_corner_radius_all(5)
	dot.add_theme_stylebox_override("panel", box)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.offset_left = -12.0
	dot.offset_top = 3.0
	dot.offset_right = -3.0
	dot.offset_bottom = 12.0
	tab.add_child(dot)
	_tab_dots[branch] = dot

## [param index] counts from the first row of the branch, so every tab starts at T1.
func _add_tier_row(index: int, skills: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "T%d" % (index + 1)
	label.tooltip_text = "Tier %d" % (index + 1)
	label.custom_minimum_size = Vector2(tier_label_width, node_size.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", HEADER_COLOR)
	row.add_child(label)

	var flow := HFlowContainer.new()
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.add_theme_constant_override("h_separation", node_gap)
	flow.add_theme_constant_override("v_separation", node_gap)
	row.add_child(flow)

	var row_nodes: Array = []
	for skill in skills:
		var node: SkillTreeNode = _nodes[skill.id]
		flow.add_child(node)
		row_nodes.append(node)
	_tier_rows.add_child(row)
	_rows.append({"row": row, "nodes": row_nodes})

func _get_row_nodes(row: Node) -> Array:
	for entry in _rows:
		if entry.row == row:
			return entry.nodes
	return []

## Tier of a skill: [member SkillDefinition.tier] if set, otherwise one below its deepest requirement.
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

#region Filters

## Hides what the "Can buy" filter leaves out, and the rows left empty.
func _apply_filters() -> void:
	var only_can_buy: bool = _can_buy_filter.button_pressed
	var any_visible: bool = false
	for entry in _rows:
		var row_visible: bool = false
		for node in entry.nodes:
			node.visible = not only_can_buy or node.state == SkillTreeNode.State.CAN_AFFORD
			row_visible = row_visible or node.visible
		entry.row.visible = row_visible
		any_visible = any_visible or row_visible
	_empty_label.visible = not any_visible
	_scroll.visible = any_visible

func _update_tab_dots() -> void:
	var can_buy: Dictionary = {}
	for node in _nodes.values():
		if node.state == SkillTreeNode.State.CAN_AFFORD:
			can_buy[node.skill.branch] = true
	for branch in _tab_dots:
		_tab_dots[branch].visible = can_buy.has(branch)

#endregion

#region Signals

func _on_tab_pressed(branch: String) -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	show_branch(branch)

func _on_can_buy_toggled(_pressed: bool) -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	_apply_filters()

func _on_node_pressed(skill_id: StringName) -> void:
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)
	select_skill(skill_id)

func _on_skill_changed(_skill_id: StringName, _level: int) -> void:
	refresh()

func _on_money_changed(_amount: float, _currency: Constants.CurrencyType) -> void:
	refresh()

#endregion
