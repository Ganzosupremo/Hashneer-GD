class_name ArmoryManager extends Node2D
## This class manages the Armory system, allowing players to upgrade weapons and ammo.
##
## This class provides methods to register items, upgrade them, and manage their upgrade levels.
 

## Signal emitted when an item is upgraded.[br]
## [param item_id]: The unique identifier for the upgraded item.[br]
## [param upgrade_type]: The type of upgrade applied.[br]
## [param new_level]: The new level of the item after the upgrade.
signal item_upgraded(item_id: String, upgrade_type: Constants.ArmoryUpgradeType, new_level: int)

var _upgrade_levels: Dictionary = {}  # Dictionary to hold upgrade levels for each item
var _registered_items: Array[IUpgradeable] = []  # List of items that can be upgraded


func _ready() -> void:
	_register_weapons()

func _register_weapons() -> void:
	# Register all weapons in the game that implement IUpgradeable
	var unlocked_weapons: Dictionary = PlayerStatsManager.get_unlocked_weapons().duplicate()
	for weapon in unlocked_weapons.values():
		register_item(weapon)
		# Register ammo as child item with special handling
		var ammo_details: AmmoDetails = weapon.get_ammo_details()
		if ammo_details:
			ammo_details.is_child = true
			register_item(ammo_details)

## Registers an item for upgrades in the Armory.[br]
## [param item]: The item implementing IUpgradeable to register.[br]
## This will check if the item implements the IUpgradeable interface and log an error if not.
func register_item(item: IUpgradeable) -> void:
	if !Interface.implements(item, IUpgradeable):
		DebugLogger.error("Item does not implement IUpgradeable: " + str(item))
		return

	_registered_items.append(item)
	DebugLogger.info("Registered item for upgrades: " + item.get_upgrade_name())

#region Main

## Upgrades an item in the Armory.[br]
## [param item_id]: The unique identifier for the item to upgrade.[br]
## [param upgrade_type]: The type of upgrade to apply.[br]
## Returns true if the upgrade was successful, false otherwise.
func upgrade_item(item_id: String, upgrade_type: Constants.ArmoryUpgradeType) -> bool:
	var item: IUpgradeable = get_item_by_id(item_id)
	if !item:
		DebugLogger.error("Item not found for upgrade: " + item_id)
		return false
	
	var current_level: int = get_upgrade_level(item_id, upgrade_type)
	var upgrade_data: ArmoryUpgradeData = get_upgrade_data(item, upgrade_type)

	if !upgrade_data or current_level >= upgrade_data.upgrade_levels:
		DebugLogger.error("Cannot upgrade for data type: " + str(upgrade_type))
		return false

	var costs: Array[float] = calculate_upgrade_cost(upgrade_data, current_level)
	if cannot_afford_upgrade(costs[0], costs[1], upgrade_data.requires_bitcoin):
		DebugLogger.error("Not enough resources to upgrade: " + item_id)
		return false

	purchase_upgrade(upgrade_data, costs[0], costs[1], upgrade_data.requires_bitcoin)

	var new_level: int = current_level + 1
	item.apply_upgrade(upgrade_type, new_level, upgrade_data.upgrade_power_per_level)
	set_upgrade_level(item_id, upgrade_type, new_level)

	item_upgraded.emit(item_id, upgrade_type, new_level)
	DebugLogger.info("Upgraded item: " + item_id + " to level " + str(new_level) + " for upgrade type: " + str(upgrade_type))
	return true

## Upgrades ammo for a specific weapon.[br]
## [param weapon_id]: The unique identifier for the weapon to upgrade ammo for.[br]
## [param upgrade_type]: The type of upgrade to apply to the ammo.[br]
## Returns true if the upgrade was successful, false otherwise.
func upgrade_ammo(weapon_id: String, upgrade_type: Constants.ArmoryUpgradeType) -> bool:
	var weapon: IUpgradeable = get_item_by_id(weapon_id)
	if !weapon or !(weapon is WeaponDetails):
		DebugLogger.error("Weapon not found for ammo upgrade: " + weapon_id)
		return false
	
	var ammo_details = weapon.get_ammo_details()
	if !ammo_details:
		DebugLogger.error("No ammo details found for weapon: " + weapon_id)
		return false
	
	var ammo_id = ammo_details.get_upgrade_id()
	var current_level: int = get_upgrade_level(ammo_id, upgrade_type)
	var upgrade_data: ArmoryUpgradeData = get_upgrade_data(ammo_details, upgrade_type)

	if !upgrade_data or current_level >= upgrade_data.upgrade_levels:
		DebugLogger.error("Cannot upgrade ammo for data type: " + str(upgrade_type))
		return false

	var costs: Array[float] = calculate_upgrade_cost(upgrade_data, current_level)
	if cannot_afford_upgrade(costs[0], costs[1], upgrade_data.requires_bitcoin):
		DebugLogger.error("Not enough resources to upgrade ammo: " + ammo_id)
		return false

	purchase_upgrade(upgrade_data, costs[0], costs[1], upgrade_data.requires_bitcoin)

	var new_level: int = current_level + 1
	ammo_details.apply_upgrade(upgrade_type, new_level, upgrade_data.upgrade_power_per_level)
	set_upgrade_level(ammo_id, upgrade_type, new_level)

	item_upgraded.emit(ammo_id, upgrade_type, new_level)
	DebugLogger.info("Upgraded ammo: " + ammo_id + " to level " + str(new_level) + " for upgrade type: " + str(upgrade_type))
	return true

## Calculate the cost of an upgrade based on the current level and upgrade data.[br]
## [param upgrade_data]: The ArmoryUpgradeData for the upgrade being calculated.[br]
## [param current_level]: The current level of the upgrade.[br]
## Returns an array containing the fiat cost and bitcoin cost.
## This method uses the base cost and multipliers defined in the ArmoryUpgradeData.
func calculate_upgrade_cost(upgrade_data: ArmoryUpgradeData, current_level: int) -> Array[float]:
	var fiat_cost: float = upgrade_data.base_cost * pow(upgrade_data.cost_multiplier, current_level)
	var bitcoin_cost: float = 0.0
	if upgrade_data.requires_bitcoin:
		bitcoin_cost = upgrade_data.bitcoin_base_cost * pow(upgrade_data.bitcoin_cost_multiplier, current_level)
	return [fiat_cost, bitcoin_cost]

## Check if the player can afford the upgrade costs.[br]
## [param cost]: The fiat cost of the upgrade.[br]
## [param bitcoin_cost]: The bitcoin cost of the upgrade.[br]
## [param requires_bitcoin]: Whether the upgrade requires bitcoin to purchase.[br]
## Returns true if the player cannot afford the upgrade, false otherwise.
func cannot_afford_upgrade(cost: float, bitcoin_cost: float, requires_bitcoin: bool = false) -> bool:
	# Check if the player has enough resources to afford the upgrade
	if requires_bitcoin:
		return BitcoinWallet.get_fiat_balance() < cost and BitcoinWallet.get_bitcoin_balance() < bitcoin_cost
	return BitcoinWallet.get_fiat_balance() < cost

## Purchase the upgrade by spending the required fiat and bitcoin costs.[br]
## [param upgrade_data]: The ArmoryUpgradeData for the upgrade being purchased.[br]
## [param cost]: The fiat cost of the upgrade.[br]
## [param bitcoin_cost]: The bitcoin cost of the upgrade.[br]
## [param requires_bitcoin]: Whether the upgrade requires bitcoin to purchase.[br]
func purchase_upgrade(upgrade_data: ArmoryUpgradeData, cost: float, bitcoin_cost: float, requires_bitcoin: bool = false) -> void:
	BitcoinWallet.spend_fiat(cost)
	if requires_bitcoin:
		BitcoinWallet.spend_bitcoin(bitcoin_cost)
	DebugLogger.info("Purchased upgrade: " + upgrade_data.upgrade_name + " for cost: " + str(cost) + " and bitcoin cost: " + str(bitcoin_cost))

#endregion

#region Getters and Setters

## Returns the upgrade level for a specific item and upgrade type.[br]
## [param item_id]: The unique identifier for the item.[br]
## [param upgrade_type]: The type of upgrade to retrieve the level for.[br]
## Returns the current upgrade level, or 0 if not set.
func get_upgrade_level(item_id: String, upgrade_type: Constants.ArmoryUpgradeType) -> int:
	if !_upgrade_levels.has(item_id):
		_upgrade_levels[item_id] = {}
	return _upgrade_levels[item_id].get(upgrade_type, 0)

## Returns the upgrade data for a specific item and upgrade type.[br]
## [param item]: The item implementing IUpgradeable.[br]
## [param upgrade_type]: The type of upgrade to retrieve data for.[br]
func get_upgrade_data(item: IUpgradeable, upgrade_type: Constants.ArmoryUpgradeType) -> ArmoryUpgradeData:
	for upgrade in item.get_available_upgrades():
		if upgrade.upgrade_type == upgrade_type:
			return upgrade
	DebugLogger.error("Upgrade data not found for type: " + str(upgrade_type))
	return null

## Returns all registered items that are not child items.
## This filters out any items that are marked as child items.
func get_all_registered_items() -> Array[IUpgradeable]:
	var valid_items: Array[IUpgradeable] = []
	for item in _registered_items:
		if !item.is_child:
			valid_items.append(item)
	return valid_items

## Returns an item by its unique ID.
## [param item_id]: The unique identifier for the item.
func get_item_by_id(item_id: String) -> IUpgradeable:
	for item in _registered_items:
		if item.get_upgrade_id() == item_id:
			return item
	DebugLogger.error("Item not found with ID: " + item_id)
	return null

## Returns a dictionary containing both weapon upgrades and ammo upgrades.
## [codeblock]
## # Structure: 
## result = {
##   "weapon_upgrades": Array[ArmoryUpgradeData],
##   "ammo_upgrades": Array[ArmoryUpgradeData],
##   "ammo_item": IUpgradeable # (the ammo details object)
## }
## [/codeblock]
func get_weapon_with_ammo_upgrades(weapon: IUpgradeable) -> Dictionary:
	var result = {
		"weapon_upgrades": weapon.get_available_upgrades(),
		"ammo_upgrades": [],
		"ammo_item": null
	}
	
	# Check if this weapon has child upgrades (ammo)
	var child_upgrades = weapon.get_child_available_upgrades()
	if child_upgrades.size() > 0:
		result["ammo_upgrades"] = child_upgrades
		
		# Find the actual ammo item for upgrade tracking
		if weapon is WeaponDetails:
			var ammo_details = weapon.get_ammo_details()
			if ammo_details:
				result["ammo_item"] = ammo_details
	
	return result

## Sets the upgrade level for a specific item and upgrade type.[br]
## [param item_id]: The unique identifier for the item.[br]
## [param upgrade_type]: The type of upgrade to set the level for.[br]
## [param level]: The new level to set for the upgrade.[br]
## This will create the entry in _upgrade_levels if it doesn't exist.
func set_upgrade_level(item_id: String, upgrade_type: Constants.ArmoryUpgradeType, level: int) -> void:
	if !_upgrade_levels.has(item_id):
		_upgrade_levels[item_id] = {}
	_upgrade_levels[item_id][upgrade_type] = level


#endregion
