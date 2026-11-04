class_name LoadoutPanel extends VBoxContainer
## Armory "Loadout" tab: choose the 2 weapons, 3 passive abilities and 1 active ability the player
## takes into each game mode. The data lives in the [code]Equipment[/code] autoload.
##
## Click a slot, then click what goes in it in the list below. Locked weapons and abilities are
## listed too, greyed out, so the player knows what the Skill Tree can unlock.

enum SlotKind { WEAPON, PASSIVE, ACTIVE }

const SLOT_SIZE: Vector2 = Vector2(150, 64)
const ITEM_SIZE: Vector2 = Vector2(170, 56)
const ICON_WIDTH: int = 40

@onready var _mode_option: OptionButton = %ModeOption
@onready var _weapon_slots: HBoxContainer = %WeaponSlots
@onready var _passive_slots: HBoxContainer = %PassiveSlots
@onready var _active_slots: HBoxContainer = %ActiveSlots
@onready var _picker_title: Label = %PickerTitle
@onready var _picker_grid: GridContainer = %PickerGrid
@onready var _info_label: Label = %InfoLabel

var _mode: int = Constants.GameModeFlag.MINING
var _slot_kind: SlotKind = SlotKind.WEAPON
var _slot_index: int = 0
var _loadout: PlayerLoadout


func _ready() -> void:
	_style_mode_popup()
	_mode_option.clear()
	_mode_option.add_item("Mining", Constants.GameModeFlag.MINING)
	_mode_option.add_item("Waves", Constants.GameModeFlag.WAVES)
	_mode_option.item_selected.connect(_on_mode_selected)
	# Deferred: the rows are rebuilt, freeing the button whose signal is still running
	Equipment.equipment_changed.connect(_on_equipment_changed, CONNECT_DEFERRED)
	visibility_changed.connect(_on_visibility_changed)
	_refresh()

func _on_equipment_changed(_changed_mode: int) -> void:
	_refresh()

# Skills may have been bought since the tab was last shown
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		_refresh()

func _on_mode_selected(index: int) -> void:
	_mode = _mode_option.get_item_id(index)
	_refresh()

func _refresh() -> void:
	_loadout = SkillProgress.build_loadout(_mode)
	_build_slots()
	_build_picker()

#region Slots

func _build_slots() -> void:
	_clear(_weapon_slots)
	_clear(_passive_slots)
	_clear(_active_slots)

	var weapons: Array[WeaponDetails] = Equipment.get_equipped_weapons(_mode, _loadout)
	for i in Equipment.MAX_WEAPONS:
		var weapon: WeaponDetails = weapons[i] if i < weapons.size() else null
		_add_slot(_weapon_slots, SlotKind.WEAPON, i, weapon.weapon_name if weapon else "Empty", weapon.weapon_texture if weapon else null)

	var passives: Array[PackedScene] = Equipment.get_equipped_passives(_mode, _loadout)
	for i in Equipment.MAX_PASSIVES:
		var scene: PackedScene = passives[i] if i < passives.size() else null
		var info: Dictionary = Equipment.get_ability_info(scene)
		_add_slot(_passive_slots, SlotKind.PASSIVE, i, info.get("name", "Empty"), info.get("icon", null))

	var active: PackedScene = Equipment.get_equipped_active(_mode, _loadout)
	var active_info: Dictionary = Equipment.get_ability_info(active)
	_add_slot(_active_slots, SlotKind.ACTIVE, 0, active_info.get("name", "Empty"), active_info.get("icon", null))

func _add_slot(container: HBoxContainer, kind: SlotKind, index: int, text: String, icon: Texture2D) -> void:
	var button: Button = _make_button(text, icon, SLOT_SIZE)
	button.toggle_mode = true
	button.button_pressed = kind == _slot_kind and index == _slot_index
	button.pressed.connect(_on_slot_pressed.bind(kind, index))
	container.add_child(button)

func _on_slot_pressed(kind: SlotKind, index: int) -> void:
	_slot_kind = kind
	_slot_index = index
	_refresh.call_deferred()

#endregion

#region Picker

func _build_picker() -> void:
	_clear(_picker_grid)
	_info_label.text = ""
	match _slot_kind:
		SlotKind.WEAPON:
			_picker_title.text = "Pick weapon %d" % (_slot_index + 1)
			_build_weapon_picker()
		SlotKind.PASSIVE:
			_picker_title.text = "Pick passive ability %d (support, runs on its own)" % (_slot_index + 1)
			_build_ability_picker(BaseAbility.AbilityKind.PASSIVE)
		SlotKind.ACTIVE:
			_picker_title.text = "Pick the active ability (adds damage, use it with Q)"
			_build_ability_picker(BaseAbility.AbilityKind.ACTIVE)

func _build_weapon_picker() -> void:
	var available: Array[WeaponDetails] = Equipment.get_available_weapons(_mode, _loadout)
	var equipped: Array[WeaponDetails] = Equipment.get_equipped_weapons(_mode, _loadout)
	for weapon in available:
		var button: Button = _make_button(weapon.weapon_name, weapon.weapon_texture, ITEM_SIZE)
		var slot: int = equipped.find(weapon)
		if slot != -1:
			button.text += "\n(slot %d)" % (slot + 1)
		button.pressed.connect(_on_weapon_picked.bind(weapon))
		button.mouse_entered.connect(_show_info.bind(_describe_weapon(weapon)))
		_picker_grid.add_child(button)
	for weapon in SkillProgress.get_all_weapons():
		if !available.has(weapon):
			_add_locked(weapon.weapon_name, weapon.weapon_texture)

func _build_ability_picker(kind: int) -> void:
	var available: Array[PackedScene] = Equipment.get_available_abilities(_mode, kind, _loadout)
	var equipped: Array[PackedScene] = []
	if kind == BaseAbility.AbilityKind.PASSIVE:
		equipped = Equipment.get_equipped_passives(_mode, _loadout)
	elif Equipment.get_equipped_active(_mode, _loadout):
		equipped = [Equipment.get_equipped_active(_mode, _loadout)]
	for scene in available:
		var info: Dictionary = Equipment.get_ability_info(scene)
		var button: Button = _make_button(info.name, info.icon, ITEM_SIZE)
		var slot: int = equipped.find(scene)
		if slot != -1:
			button.text += "\n(equipped)" if kind == BaseAbility.AbilityKind.ACTIVE else "\n(slot %d)" % (slot + 1)
		button.pressed.connect(_on_ability_picked.bind(scene, kind))
		button.mouse_entered.connect(_show_info.bind(_describe_ability(info)))
		_picker_grid.add_child(button)
	# Locked ones that would work in this mode
	for entry in SkillProgress.get_all_abilities():
		var scene: PackedScene = entry.scene
		if available.has(scene) or (int(entry.modes) & _mode) == 0:
			continue
		var info: Dictionary = Equipment.get_ability_info(scene)
		if info.kind == kind:
			_add_locked(info.name, info.icon)
	if _picker_grid.get_child_count() == 0:
		_info_label.text = "Nothing here yet. Unlock abilities in the Skill Tree."

func _on_weapon_picked(weapon: WeaponDetails) -> void:
	Equipment.equip_weapon(_mode, _slot_index, weapon)

func _on_ability_picked(scene: PackedScene, kind: int) -> void:
	if kind == BaseAbility.AbilityKind.ACTIVE:
		Equipment.equip_active(_mode, scene)
	else:
		Equipment.equip_passive(_mode, _slot_index, scene)

func _show_info(text: String) -> void:
	_info_label.text = text

func _add_locked(item_name: String, icon: Texture2D) -> void:
	var button: Button = _make_button("%s\n(locked)" % item_name, icon, ITEM_SIZE)
	button.disabled = true
	button.tooltip_text = "Unlock it in the Skill Tree"
	button.modulate = Color(1, 1, 1, 0.5)
	_picker_grid.add_child(button)

func _describe_weapon(weapon: WeaponDetails) -> String:
	var text: String = "%s: %.2f shots/s" % [weapon.weapon_name, weapon.get_fire_rate()]
	if weapon.special:
		text += ". Special (right click): %s. %s" % [weapon.special.special_name, weapon.special.get_summary(weapon)]
	return text

func _describe_ability(info: Dictionary) -> String:
	return "%s: %s (cooldown %.0f s)" % [info.name, info.description, info.cooldown]

#endregion

func _make_button(text: String, icon: Texture2D, min_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", ICON_WIDTH)
	button.custom_minimum_size = min_size
	# Fixed size: without clipping a Button grows to fit its text, so a long weapon name widened
	# the whole row (and pushed it off screen) and a short one shrank it. Long names get "..." and
	# the full text shows as a tooltip.
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.tooltip_text = text
	button.add_theme_color_override("font_color", Color("d9edf2"))
	button.add_theme_color_override("font_hover_color", Color("e8ffff"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	button.add_theme_color_override("font_hover_pressed_color", Color("ffffff"))
	button.add_theme_color_override("font_focus_color", Color("ffffff"))
	button.add_theme_color_override("font_disabled_color", Color("71808a"))
	button.add_theme_stylebox_override("normal", _button_style(Color("07101f"), Color("29495c"), 1))
	button.add_theme_stylebox_override("hover", _button_style(Color("0b2835"), Color("20d6c8"), 2))
	button.add_theme_stylebox_override("pressed", _button_style(Color("b64d09"), Color("ff9a32"), 3))
	button.add_theme_stylebox_override("focus", _button_style(Color("12394a"), Color("72fff1"), 2))
	button.add_theme_stylebox_override("disabled", _button_style(Color("080d16"), Color("26333c"), 1))
	return button


func _button_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


func _style_mode_popup() -> void:
	var popup := _mode_option.get_popup()
	popup.add_theme_color_override("font_color", Color("d9edf2"))
	popup.add_theme_color_override("font_hover_color", Color("ffffff"))
	popup.add_theme_stylebox_override("panel", _button_style(Color("07101f"), Color("20d6c8"), 1))
	popup.add_theme_stylebox_override("hover", _button_style(Color("12394a"), Color("20d6c8"), 1))

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
