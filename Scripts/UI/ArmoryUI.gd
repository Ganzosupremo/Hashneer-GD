class_name ArmoryUI extends Control
## This class is responsible for managing the Armory UI, including displaying available upgrades and handling user interactions.
##
## It connects to the [class ArmoryManager] to retrieve upgradeable items and their details, allowing players to view and apply upgrades.

@onready var _upgradeables_list: ItemList = %IUpgradeableList
@onready var _armory_manager: ArmoryManager = $ArmoryManager


@onready var _fiat_balance_label: Label = %FiatBalanceLabel
@onready var _bitcoin_balance_label: Label = %BitcoinBalanceLabel
@onready var _upgrades_container: VBoxContainer = %UpgradesContainer
@onready var _ammo_upgrades_container: VBoxContainer = %AmmoUpgradesContainer


# Weapon stats UI labels
@onready var _fire_rate_label: Label = %FireRateLabel
@onready var _damage_multiplier_label: Label = %DamageMultiplierLabel
@onready var _spread_label: Label = %SpreadLabel
@onready var _level_label: Label = %LevelLabel

@onready var _weapon_icon: TextureRect = %WeaponIcon
@onready var _weapon_name: Label = %WeaponName
@onready var _weapon_description_label: Label = %WeaponDescriptionLabel



const UPGRADE_TEMPLATE_UI = preload("res://Scenes/UI/UpgradeTemplateUI.tscn")
var _current_item: IUpgradeable = null

func _ready() -> void:
	_populate_item_list()
	_upgradeables_list.item_selected.connect(_on_item_selected)
	_update_balance_display()

func _populate_item_list() -> void:
	_upgradeables_list.clear()

	for item in _armory_manager.get_all_registered_items():
		var index: int = _upgradeables_list.add_item(item.get_upgrade_name())
		_upgradeables_list.set_item_icon(index, item.get_display_icon())
		_upgradeables_list.set_item_metadata(index, item)
	_upgradeables_list.select(0)
	_upgradeables_list.item_selected.emit(0)

func _update_stats_display() -> void:
	if !_current_item:
		return
	
	var stats: Dictionary = _current_item.get_current_stats()
	_weapon_name.text = stats.get("Weapon Name", "Unknown Weapon")
	_weapon_icon.texture = stats.get("Weapon Texture", null)
	_weapon_description_label.text = _current_item.get_upgrade_description()
	_fire_rate_label.text = "Fire Rate: {0}/sec".format([stats.get("ShotsPerSecond", 1.0)])
	_damage_multiplier_label.text = "💥 Damage: " + stats.get("Damage", 0.0) + "x"
	_spread_label.text = "Spread: " + stats.get("Spread", 0.0)
	_level_label.text = "Level: " + stats.get("Level", 0)

func _update_balance_display() -> void:
	_fiat_balance_label.text = "Fiat: $%s" % Utils.format_currency(BitcoinWallet.get_fiat_balance(), true)
	_bitcoin_balance_label.text = "Bitcoin: ₿%s" % Utils.format_currency(BitcoinWallet.get_bitcoin_balance(), true)

func _on_item_selected(index: int) -> void:
	_current_item = _upgradeables_list.get_item_metadata(index)
	if _current_item is WeaponDetails:
		var child_item: AmmoDetails = _current_item.get_ammo_details()
		_display_item_upgrades(_current_item, child_item)
		_update_stats_display()
		return

	_display_item_upgrades(_current_item)
	_update_stats_display()

func _on_upgrade_button_pressed(item: IUpgradeable, upgrade_data: ArmoryUpgradeData) -> void:
	var success: bool = false
	
	# Check if this is an ammo upgrade (child item)
	if item.is_child and _current_item is WeaponDetails:
		# This is an ammo upgrade, use the weapon upgrade ammo method
		success = _armory_manager.upgrade_ammo(_current_item.get_upgrade_id(), upgrade_data.upgrade_type)
	else:
		# Regular item upgrade
		success = _armory_manager.upgrade_item(item.get_upgrade_id(), upgrade_data.upgrade_type)
	
	if !success:
		DebugLogger.error("Upgrade failed for item: " + item.get_upgrade_name())
		return 
	
	# Refresh the entire display to show updated levels and costs
	if _current_item is WeaponDetails:
		var child_item: AmmoDetails = _current_item.get_ammo_details()
		_display_item_upgrades(_current_item, child_item)
	else:
		_display_item_upgrades(_current_item)
	_update_stats_display()
	_update_balance_display()

func _update_item_upgrades(item: IUpgradeable) -> void:
	# Display available upgrades for the selected item
	var upgrades = item.get_available_upgrades()
	var children = _upgrades_container.get_children()
	
	for i in range(min(children.size(), upgrades.size())):
		var child = children[i]
		var upgrade = upgrades[i]
		var costs: Array[float] = _armory_manager.calculate_upgrade_cost(upgrade, _armory_manager.get_upgrade_level(item.get_upgrade_id(), upgrade.upgrade_type))
		child.update_upgrade_details(_armory_manager.get_upgrade_level(item.get_upgrade_id(), upgrade.upgrade_type), costs[0], costs[1])


func _display_item_upgrades(item: IUpgradeable, child_item: IUpgradeable = null) -> void:
	for child in _upgrades_container.get_children():
		child.queue_free()  # Clear previous upgrade UI elements
	for child in _ammo_upgrades_container.get_children():
		child.queue_free()  # Clear previous ammo upgrade UI elements

	await get_tree().process_frame  # Ensure the UI is updated before adding new elements
	
	# Display weapon upgrades
	for upgrade in item.get_available_upgrades():
		var upgrade_ui: UpgradeTemplateUI = UPGRADE_TEMPLATE_UI.instantiate()
		_upgrades_container.add_child(upgrade_ui)
		var costs: Array[float] = _armory_manager.calculate_upgrade_cost(upgrade, _armory_manager.get_upgrade_level(item.get_upgrade_id(), upgrade.upgrade_type))
		upgrade_ui.set_upgrade_details(upgrade.get_upgrade_name().capitalize(), _armory_manager.get_upgrade_level(item.get_upgrade_id(), upgrade.upgrade_type), upgrade.get_upgrade_description(), costs[0], costs[1])
		if !upgrade_ui.upgrade_button.pressed.is_connected(Callable(self, &"_on_upgrade_button_pressed").bind(item, upgrade)):
			upgrade_ui.upgrade_button.pressed.connect(Callable(self, &"_on_upgrade_button_pressed").bind(item, upgrade))

	# Display ammo upgrades if child_item exists
	if child_item == null: return
	
	for upgrade in child_item.get_available_upgrades():
		var ammo_upgrade_ui: UpgradeTemplateUI = UPGRADE_TEMPLATE_UI.instantiate()
		_ammo_upgrades_container.add_child(ammo_upgrade_ui)
		var ammo_costs: Array[float] = _armory_manager.calculate_upgrade_cost(upgrade, _armory_manager.get_upgrade_level(child_item.get_upgrade_id(), upgrade.upgrade_type))
		ammo_upgrade_ui.set_upgrade_details(upgrade.get_upgrade_name().capitalize(), _armory_manager.get_upgrade_level(child_item.get_upgrade_id(), upgrade.upgrade_type), upgrade.get_upgrade_description(), ammo_costs[0], ammo_costs[1])
		if !ammo_upgrade_ui.upgrade_button.pressed.is_connected(Callable(self, &"_on_upgrade_button_pressed").bind(child_item, upgrade)):
			ammo_upgrade_ui.upgrade_button.pressed.connect(Callable(self, &"_on_upgrade_button_pressed").bind(child_item, upgrade))
