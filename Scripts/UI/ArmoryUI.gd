class_name ArmoryUI extends Control
## The Armory: pick a weapon on the left, see its stats and special in the middle and buy weapon,
## ammo and special upgrades on the right.
##
## It connects to the [ArmoryManager] to list the weapons and buy upgrades. Hovering an upgrade's
## buy button previews the stats of its next level ("4.0 -> 4.4").

@onready var _armory_manager: ArmoryManager = $ArmoryManager
@onready var _weapons_list: ItemList = %IUpgradeableList

@onready var _fiat_balance_label: Label = %FiatBalanceLabel
@onready var _bitcoin_balance_label: Label = %BitcoinBalanceLabel

@onready var _weapon_icon: TextureRect = %WeaponIcon
@onready var _weapon_name: Label = %WeaponName
@onready var _level_label: Label = %LevelLabel
@onready var _weapon_description_label: Label = %WeaponDescriptionLabel
@onready var _stats_grid: GridContainer = %StatsGrid
@onready var _special_name_label: Label = %SpecialNameLabel
@onready var _special_description_label: Label = %SpecialDescriptionLabel

@onready var _weapon_upgrades_container: VBoxContainer = %UpgradesContainer
@onready var _ammo_upgrades_container: VBoxContainer = %AmmoUpgradesContainer
@onready var _special_upgrades_container: VBoxContainer = %SpecialUpgradesContainer
@onready var _ammo_section: Control = %AmmoSection
@onready var _special_section: Control = %SpecialSection

const UPGRADE_TEMPLATE_UI = preload("res://Scenes/UI/UpgradeTemplateUI.tscn")
const PREVIEW_COLOR: Color = Color(0.55, 1.0, 0.6)
## Weapon upgrade types shown in the Special section instead of the weapon one.
const SPECIAL_UPGRADE_TYPES: Array = [
	Constants.ArmoryUpgradeType.SPECIAL_COOLDOWN_REDUCTION,
	Constants.ArmoryUpgradeType.SPECIAL_POWER,
]

var _current_weapon: WeaponDetails = null


func _ready() -> void:
	$VBoxContainer/Header.text = "BITCOIN ARMORY"
	$VBoxContainer/Body/Tabs/Upgrades/LeftBar/WeaponsTitle.text = "WEAPON INVENTORY"
	$VBoxContainer/Body/Tabs/Upgrades/CentralBar/Margin/Scroll/VBox/StatsTitle.text = "WEAPON TELEMETRY"
	$VBoxContainer/Body/Tabs/Upgrades/RightBar/Margin/Scroll/Sections/WeaponSection/Title.text = "WEAPON UPGRADES"
	$VBoxContainer/Body/Tabs/Upgrades/RightBar/Margin/Scroll/Sections/AmmoSection/Title.text = "AMMUNITION"
	$VBoxContainer/Body/Tabs/Upgrades/RightBar/Margin/Scroll/Sections/SpecialSection/Title.text = "SPECIAL SYSTEM"
	$VBoxContainer/Body/Tabs/Loadout/TopRow/ModeLabel.text = "GAME MODE //"
	$VBoxContainer/Body/Tabs/Loadout/SlotsRow/WeaponsBox/Title.text = "WEAPON SLOTS"
	$VBoxContainer/Body/Tabs/Loadout/SlotsRow/PassivesBox/Title.text = "PASSIVE MODULES"
	$VBoxContainer/Body/Tabs/Loadout/SlotsRow/ActiveBox/Title.text = "ACTIVE MODULE [Q]"
	$VBoxContainer/Body/Tabs/Loadout/PickerPanel/Margin/VBox/PickerTitle.text = "SELECT A MODULE"
	_weapons_list.item_selected.connect(_on_weapon_selected)
	_populate_weapon_list()
	_update_balance_display()
	_normalize_balance_labels()

#region Weapon list

func _populate_weapon_list() -> void:
	_weapons_list.clear()
	for item in _armory_manager.get_all_registered_items():
		if not item is WeaponDetails:
			continue
		var index: int = _weapons_list.add_item(_get_list_text(item), item.get_display_icon())
		_weapons_list.set_item_metadata(index, item)
	if _weapons_list.item_count == 0:
		_show_empty_state()
		return
	_weapons_list.select(0)
	_on_weapon_selected(0)

func _get_list_text(weapon: WeaponDetails) -> String:
	var level: int = weapon.get_total_upgrade_level()
	if weapon.get_ammo_details():
		level += weapon.get_ammo_details().get_total_upgrade_level()
	return "%s  Lv.%d" % [weapon.weapon_name, level]

func _refresh_list_texts() -> void:
	for i in _weapons_list.item_count:
		_weapons_list.set_item_text(i, _get_list_text(_weapons_list.get_item_metadata(i)))

func _show_empty_state() -> void:
	_weapon_name.text = "No weapons yet"
	_weapon_description_label.text = "Unlock weapons in the Skill Tree to upgrade them here."
	_special_name_label.text = ""
	_special_description_label.text = ""
	_level_label.text = ""

func _on_weapon_selected(index: int) -> void:
	_current_weapon = _weapons_list.get_item_metadata(index)
	_refresh_weapon_view()

func _refresh_weapon_view() -> void:
	if _current_weapon == null:
		return
	_update_header()
	_update_stats_display()
	_display_upgrades()

#endregion

#region Details

func _update_header() -> void:
	_weapon_icon.texture = _current_weapon.weapon_texture
	_weapon_name.text = _current_weapon.weapon_name
	_weapon_description_label.text = _current_weapon.get_upgrade_description()
	_weapon_description_label.visible = !_weapon_description_label.text.is_empty() and _weapon_description_label.text != "No description available"
	var level: int = _current_weapon.get_total_upgrade_level()
	if _current_weapon.get_ammo_details():
		level += _current_weapon.get_ammo_details().get_total_upgrade_level()
	_level_label.text = "Upgrade level %d" % level
	var special: WeaponSpecial = _current_weapon.special
	_special_name_label.text = "Special (right click): %s" % special.special_name if special else "No special"
	_special_description_label.text = special.get_summary(_current_weapon) if special else ""

## Rebuilds the stats grid. [param preview] holds the rows after the hovered upgrade, values that
## change are shown as "old -> new".
func _update_stats_display(preview: Array = []) -> void:
	for child in _stats_grid.get_children():
		_stats_grid.remove_child(child)
		child.queue_free()
	var current: Array = _get_stat_rows(_current_weapon)
	var current_values: Dictionary = {}
	for row in current:
		current_values[row[0]] = row[1]
	# With a preview, list its rows: an upgrade can add a row (the first pierce level, for example)
	var rows: Array = preview if !preview.is_empty() else current
	for row in rows:
		var old_value: String = current_values.get(row[0], "0")
		var name_label: Label = Label.new()
		name_label.theme_type_variation = &"NormalText"
		name_label.text = row[0]
		var value_label: Label = Label.new()
		value_label.theme_type_variation = &"NormalText"
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.text = old_value
		if old_value != row[1]:
			value_label.text = "%s → %s" % [old_value, row[1]]
			value_label.text = "%s  ->  %s" % [old_value, row[1]]
			value_label.modulate = PREVIEW_COLOR
		_stats_grid.add_child(name_label)
		_stats_grid.add_child(value_label)

## Returns [name, value] rows for the weapon's current stats.
func _get_stat_rows(weapon: WeaponDetails) -> Array:
	var rows: Array = []
	var ammo: AmmoDetails = weapon.get_ammo_details()
	var is_laser: bool = ammo != null and ammo.bullet_type == AmmoDetails.BulletType.LASER
	if ammo:
		# The value stored by get_final_damage is recomputed before every shot in game
		rows.append(["Damage" if !is_laser else "Damage per tick", "%.1f" % ammo.get_final_damage(1.0, weapon.get_damage_multiplier())])
	rows.append(["Weapon damage bonus", "+%d%%" % roundi(weapon.get_damage_multiplier() * 100.0)])
	if !is_laser:
		rows.append(["Fire rate", "%.2f/s" % weapon.get_fire_rate()])
		rows.append(["Spread", "%.3f" % weapon.get_spread()])
	if weapon.precharge_time > 0.0:
		rows.append(["Charge up", "%.2f s" % weapon.get_precharge_time()])
	if ammo:
		if is_laser:
			rows.append(["Beam length", "%d" % roundi(ammo.get_laser_length())])
		else:
			var bonus: int = int(ammo.upgrade_modifiers.get("bullet_count_upgrade", 0))
			var count_min: int = ammo.bullets_per_shoot_min + bonus
			var count_max: int = ammo.bullets_per_shoot_max + bonus
			rows.append(["Bullets per shot", str(count_min) if count_min == count_max else "%d-%d" % [count_min, count_max]])
			rows.append(["Bullet speed", "%d" % roundi(ammo.get_ammo_speed())])
		if ammo.bullet_type == AmmoDetails.BulletType.PIERCING or ammo.get_pierces() > 0:
			rows.append(["Pierce", str(ammo.get_pierces())])
		if ammo.bullet_type == AmmoDetails.BulletType.BOUNCING or ammo.get_bounces() > 0:
			rows.append(["Bounces", str(ammo.get_bounces())])
		if ammo.bullet_type == AmmoDetails.BulletType.EXPLOSIVE:
			rows.append(["Blast radius", "%d" % roundi(ammo.get_explosion_radius())])
	if weapon.special:
		rows.append(["Special cooldown", "%.1f s" % weapon.get_special_cooldown()])
		rows.append(["Special power", "x%.2f" % weapon.get_special_power_multiplier()])
	return rows

func _update_balance_display() -> void:
	call_deferred("_normalize_balance_labels")
	_fiat_balance_label.text = "Fiat: $%s" % Utils.format_currency(BitcoinWallet.get_fiat_balance(), true)
	_bitcoin_balance_label.text = "Bitcoin: ₿%s" % Utils.format_btc(BitcoinWallet.get_bitcoin_balance())

#endregion


func _normalize_balance_labels() -> void:
	_fiat_balance_label.text = "FIAT // $%s" % Utils.format_currency(BitcoinWallet.get_fiat_balance(), true)
	_bitcoin_balance_label.text = "BTC // %s" % Utils.format_btc(BitcoinWallet.get_bitcoin_balance())

#region Upgrades

func _display_upgrades() -> void:
	for container in [_weapon_upgrades_container, _ammo_upgrades_container, _special_upgrades_container]:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()

	for upgrade in _current_weapon.get_available_upgrades():
		var container: VBoxContainer = _special_upgrades_container if SPECIAL_UPGRADE_TYPES.has(upgrade.upgrade_type) else _weapon_upgrades_container
		_add_upgrade_row(container, _current_weapon, upgrade)

	var ammo: AmmoDetails = _current_weapon.get_ammo_details()
	if ammo:
		for upgrade in ammo.get_available_upgrades():
			_add_upgrade_row(_ammo_upgrades_container, ammo, upgrade)
	_ammo_section.visible = _ammo_upgrades_container.get_child_count() > 0
	_special_section.visible = _special_upgrades_container.get_child_count() > 0

func _add_upgrade_row(container: VBoxContainer, item: IUpgradeable, upgrade: ArmoryUpgradeData) -> void:
	var row: UpgradeTemplateUI = UPGRADE_TEMPLATE_UI.instantiate()
	container.add_child(row)
	var level: int = _armory_manager.get_upgrade_level(item.get_upgrade_id(), upgrade.upgrade_type)
	var costs: Array[float] = _armory_manager.calculate_upgrade_cost(upgrade, level)
	var reason: String = _armory_manager.get_block_reason(item, upgrade)
	if level >= upgrade.upgrade_levels:
		reason = ""
	row.set_upgrade_state(upgrade.get_upgrade_name().capitalize(), upgrade.get_upgrade_description(), level, upgrade.upgrade_levels, costs[0], costs[1], reason)
	row.upgrade_button.pressed.connect(_on_upgrade_button_pressed.bind(item, upgrade))
	row.preview_requested.connect(_on_preview_requested.bind(item, upgrade))

func _on_upgrade_button_pressed(item: IUpgradeable, upgrade: ArmoryUpgradeData) -> void:
	var success: bool = false
	if item is AmmoDetails:
		success = _armory_manager.upgrade_ammo(_current_weapon.get_upgrade_id(), upgrade.upgrade_type)
	else:
		success = _armory_manager.upgrade_item(item.get_upgrade_id(), upgrade.upgrade_type)
	if !success:
		DebugLogger.error("Upgrade failed for item: " + item.get_upgrade_name())
		return
	# Rebuilding the rows frees the button that was pressed, so wait until its signal is done
	_after_purchase.call_deferred()

func _after_purchase() -> void:
	_refresh_weapon_view()
	_refresh_list_texts()
	_update_balance_display()

## Shows the stats the next level of [param upgrade] gives while its buy button is hovered.
func _on_preview_requested(is_showing: bool, item: IUpgradeable, upgrade: ArmoryUpgradeData) -> void:
	if !is_showing:
		_update_stats_display()
		return
	var level: int = _armory_manager.get_upgrade_level(item.get_upgrade_id(), upgrade.upgrade_type)
	if level >= upgrade.upgrade_levels:
		return
	# Apply the next level for a moment, read the stats and put the real level back
	item.apply_upgrade(upgrade.upgrade_type, level + 1, upgrade.upgrade_power_per_level)
	var preview: Array = _get_stat_rows(_current_weapon)
	item.apply_upgrade(upgrade.upgrade_type, level, upgrade.upgrade_power_per_level)
	_update_stats_display(preview)

#endregion
