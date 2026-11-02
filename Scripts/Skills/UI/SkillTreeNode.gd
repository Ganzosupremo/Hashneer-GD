class_name SkillTreeNode extends Button
## One skill in the [SkillTreeView]: icon, level, mode badges and a border colored by its state.
##
## The layout lives in [code]Scenes/SkillTreeSystem/SkillTreeNode.tscn[/code]. Pressing it only
## selects the skill, buying happens in the [SkillDetailPanel].

enum State {
	## Requirements not met.
	LOCKED,
	CANNOT_AFFORD,
	CAN_AFFORD,
	MAXED,
}

const STATE_COLORS: Dictionary = {
	State.LOCKED: Color(0.35, 0.35, 0.42, 0.9),
	State.CANNOT_AFFORD: Color(0.85, 0.32, 0.3, 1.0),
	State.CAN_AFFORD: Color(0.3, 0.9, 0.45, 1.0),
	State.MAXED: Color(1.0, 0.843, 0.0, 1.0),
}
const BACKGROUND_COLOR: Color = Color(0.04, 0.04, 0.07, 0.92)
const HOVER_BACKGROUND_COLOR: Color = Color(0.1, 0.1, 0.16, 0.95)
const SELECTED_BORDER_COLOR: Color = Color(1, 1, 1, 1)

@onready var _icon: TextureRect = %Icon
@onready var _lock_label: Label = %LockLabel
@onready var _level_label: Label = %LevelLabel
@onready var _level_progress: ProgressBar = %LevelProgress
@onready var _name_label: Label = %NameLabel
@onready var _mining_badge: Control = %MiningBadge
@onready var _waves_badge: Control = %WavesBadge

var skill: SkillDefinition
var state: State = State.LOCKED
var _selected: bool = false


func _ready() -> void:
	if skill:
		refresh()

func setup(_skill: SkillDefinition) -> void:
	skill = _skill
	tooltip_text = skill.display_name
	if is_node_ready():
		refresh()

## Center of the node in the parent's coordinates, used to draw the requirement lines.
func get_center() -> Vector2:
	return position + size * 0.5

func refresh() -> void:
	if skill == null:
		return
	var level: int = SkillProgress.get_level(skill.id)
	var maxed: bool = level >= skill.max_level
	if maxed:
		state = State.MAXED
	elif not SkillProgress.is_unlocked(skill.id):
		state = State.LOCKED
	elif SkillProgress.can_afford(skill.id):
		state = State.CAN_AFFORD
	else:
		state = State.CANNOT_AFFORD

	_icon.texture = skill.get_icon(maxed)
	_icon.modulate = Color(0.3, 0.3, 0.36) if state == State.LOCKED else Color.WHITE
	_lock_label.visible = state == State.LOCKED
	_level_label.text = "MAX" if maxed else "%d/%d" % [level, skill.max_level]
	_level_progress.visible = skill.max_level > 1
	_level_progress.max_value = skill.max_level
	_level_progress.value = level
	_name_label.text = skill.display_name
	_mining_badge.visible = (skill.modes & Constants.GameModeFlag.MINING) != 0
	_waves_badge.visible = (skill.modes & Constants.GameModeFlag.WAVES) != 0
	_update_style()

func set_selected(value: bool) -> void:
	_selected = value
	_update_style()

## Fades nodes that don't work in the mode picked by the filter.
func set_dimmed(value: bool) -> void:
	modulate.a = 0.3 if value else 1.0

func _update_style() -> void:
	var border: Color = SELECTED_BORDER_COLOR if _selected else STATE_COLORS[state]
	var normal: StyleBoxFlat = _make_box(BACKGROUND_COLOR, border)
	var hover: StyleBoxFlat = _make_box(HOVER_BACKGROUND_COLOR, border)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("disabled", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("hover_pressed", hover)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_box(background: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(5 if _selected else 3)
	box.set_corner_radius_all(14)
	if state == State.CAN_AFFORD or state == State.MAXED or _selected:
		box.shadow_color = Color(border, 0.45)
		box.shadow_size = 8
	return box
