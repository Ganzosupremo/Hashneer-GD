class_name PlayerInventory extends Node2D
## Manages player's inventory including ores, currencies, and other items
##
## This inventory is automatically integrated with the PickupsCollector2D through InventoryAccessSettings.
## The following methods are called by the item drops addon:[br]
## - add_to_inventory(resource, amount) - Add items when picked up[br]
## - remove_from_inventory(resource, amount) - Remove items when consumed[br]
## - get_inventory_contents() - Query current inventory state[br]
##[br]
## Tracks:[br]
## - Ores: Count and total value by ore type[br]
## - Currencies: Amount by currency type[br]
## - Generic items: For future expansion

signal item_added(resource: Resource, amount: float)
signal item_removed(resource: Resource, amount: float)
signal inventory_cleared()
signal ore_collected(ore_type: OreDetails.OreType, value: float)
signal currency_collected(currency_type: Constants.CurrencyType, amount: float)

## Dictionary mapping OreType → {count: int, total_value: float}
var _ore_inventory: Dictionary = {}

## Dictionary mapping CurrencyType → amount
var _currency_inventory: Dictionary = {}

## Generic items inventory (for future expansion)
var _items_inventory: Dictionary = {}


func _ready() -> void:
	reset_inventory()


## Add any resource to inventory (ores, currencies, items)
## Called by PickupsCollector2D when an item is picked up
func add_to_inventory(resource: Resource, amount: float) -> bool:
	if resource is OrePickupResource:
		return _add_ore(resource, amount)
	elif resource is CurrencyPickupResource:
		return _add_currency(resource, amount)
	else:
		# Generic item handling for future expansion
		DebugLogger.warn("Unknown resource type: %s" % resource.get_class())
		return false


## Remove any resource from inventory (ores, currencies, items)
## Can be used by InventoryAccessSettings for item consumption
func remove_from_inventory(resource: Resource, amount: float) -> bool:
	if resource is OrePickupResource:
		return remove_ore(resource.ore_type, int(amount))
	elif resource is CurrencyPickupResource:
		return remove_currency(resource.currency_type, amount)
	else:
		DebugLogger.warn("Cannot remove unknown resource type: %s" % resource.get_class())
		return false


## Get inventory contents as a dictionary
## Returns combined inventory data for ores, currencies, and items
## Can be used by InventoryAccessSettings to query inventory state
func get_inventory_contents() -> Dictionary:
	return {
		"ores": _ore_inventory.duplicate(true),
		"currencies": _currency_inventory.duplicate(true),
		"items": _items_inventory.duplicate(true)
	}


## Check if inventory has a specific resource with sufficient amount
func has_resource(resource: Resource, amount: float) -> bool:
	if resource is OrePickupResource:
		return get_ore_count(resource.ore_type) >= int(amount)
	elif resource is CurrencyPickupResource:
		return get_currency_amount(resource.currency_type) >= amount
	return false


## Add ore to inventory
func _add_ore(ore_resource: OrePickupResource, amount: float) -> bool:
	var ore_type = ore_resource.ore_type
	
	# Skip dirt
	if ore_type == OreDetails.OreType.DIRT:
		return false
	
	# Initialize ore entry if not exists
	if not _ore_inventory.has(ore_type):
		_ore_inventory[ore_type] = {"count": 0, "total_value": 0.0}
	
	# Add to inventory
	_ore_inventory[ore_type]["count"] += int(amount)
	_ore_inventory[ore_type]["total_value"] += ore_resource.ore_value * amount
	
	# Emit signals
	ore_collected.emit(ore_type, ore_resource.ore_value * amount)
	item_added.emit(ore_resource, amount)
	
	# Debug logging
	DebugLogger.info("Collected %s ore! Count: %d | Value: %.2f" % [
		Utils.enum_label(OreDetails.OreType, ore_type),
		_ore_inventory[ore_type]["count"],
		_ore_inventory[ore_type]["total_value"]
	])
	
	return true


## Add currency to inventory
func _add_currency(currency_resource: CurrencyPickupResource, amount: float) -> bool:
	var currency_type = currency_resource.currency_type
	var currency_amount = currency_resource.amount * amount
	
	# Initialize currency entry if not exists
	if not _currency_inventory.has(currency_type):
		_currency_inventory[currency_type] = 0.0
	
	# Add to inventory
	_currency_inventory[currency_type] += currency_amount
	
	# Handle special cases
	match currency_type:
		Constants.CurrencyType.FIAT:
			# Fiat is handled by GameManager or other systems
			pass
		Constants.CurrencyType.BITCOIN:
			# Mine a new block only if this level hasn't been mined before
			var lvl: int = GameManager.get_current_level()
			if !BitcoinNetwork.is_level_mined(lvl):
				BitcoinNetwork.mine_block("Player")
	
	# Emit signals
	currency_collected.emit(currency_type, currency_amount)
	item_added.emit(currency_resource, amount)
	
	DebugLogger.info("Collected %s! Amount: %.2f | Total: %.2f" % [
		Utils.enum_label(Constants.CurrencyType, currency_type),
		currency_amount,
		_currency_inventory[currency_type]
	])
	
	return true


#region Ore Inventory Methods

## Get ore count by type
func get_ore_count(ore_type: OreDetails.OreType) -> int:
	if _ore_inventory.has(ore_type):
		return _ore_inventory[ore_type]["count"]
	return 0


## Get total value of specific ore type
func get_ore_value(ore_type: OreDetails.OreType) -> float:
	if _ore_inventory.has(ore_type):
		return _ore_inventory[ore_type]["total_value"]
	return 0.0


## Get total value of all ores
func get_total_ore_value() -> float:
	var total = 0.0
	for ore_data in _ore_inventory.values():
		total += ore_data["total_value"]
	return total


## Get all ores data as a dictionary
func get_all_ores() -> Dictionary:
	return _ore_inventory.duplicate(true)


## Remove specific amount of ore
func remove_ore(ore_type: OreDetails.OreType, amount: int) -> bool:
	if not _ore_inventory.has(ore_type):
		return false
	
	if _ore_inventory[ore_type]["count"] < amount:
		return false
	
	# Calculate value per ore
	var value_per_ore = 0.0
	if _ore_inventory[ore_type]["count"] > 0:
		value_per_ore = _ore_inventory[ore_type]["total_value"] / float(_ore_inventory[ore_type]["count"])
	
	# Decrement count and value
	_ore_inventory[ore_type]["count"] -= amount
	_ore_inventory[ore_type]["total_value"] -= value_per_ore * amount
	
	# Remove if empty
	if _ore_inventory[ore_type]["count"] <= 0:
		_ore_inventory.erase(ore_type)
	
	item_removed.emit(null, amount)
	return true


## Clear all ores (e.g., when selling at shop)
func clear_ores() -> void:
	_ore_inventory.clear()
	_initialize_ore_inventory()
	DebugLogger.info("Ore inventory cleared")

#endregion


#region Currency Inventory Methods

## Get currency amount by type
func get_currency_amount(currency_type: Constants.CurrencyType) -> float:
	if _currency_inventory.has(currency_type):
		return _currency_inventory[currency_type]
	return 0.0


## Get all currencies
func get_all_currencies() -> Dictionary:
	return _currency_inventory.duplicate()


## Remove/spend currency
func remove_currency(currency_type: Constants.CurrencyType, amount: float) -> bool:
	if not _currency_inventory.has(currency_type):
		return false
	
	if _currency_inventory[currency_type] < amount:
		return false
	
	_currency_inventory[currency_type] -= amount
	
	if _currency_inventory[currency_type] <= 0:
		_currency_inventory.erase(currency_type)
	
	return true


## Clear all currencies
func clear_currencies() -> void:
	_currency_inventory.clear()
	_initialize_currency_inventory()
	DebugLogger.info("Currency inventory cleared")

#endregion


#region General Inventory Methods

## Reset entire inventory
func reset_inventory() -> void:
	_ore_inventory.clear()
	_currency_inventory.clear()
	_items_inventory.clear()
	
	_initialize_ore_inventory()
	_initialize_currency_inventory()
	
	inventory_cleared.emit()
	DebugLogger.info("Inventory reset")


## Initialize ore inventory with all ore types
func _initialize_ore_inventory() -> void:
	for ore_type in OreDetails.OreType.values():
		if ore_type != OreDetails.OreType.DIRT:  # Skip dirt
			_ore_inventory[ore_type] = {"count": 0, "total_value": 0.0}


## Initialize currency inventory with all currency types
func _initialize_currency_inventory() -> void:
	for currency_type in Constants.CurrencyType.values():
		_currency_inventory[currency_type] = 0.0


## Get summary of entire inventory
func get_inventory_summary() -> Dictionary:
	return {
		"ores": get_all_ores(),
		"currencies": get_all_currencies(),
		"total_ore_value": get_total_ore_value(),
		"ore_count": _get_total_ore_count()
	}


## Get total count of all ores
func _get_total_ore_count() -> int:
	var total = 0
	for ore_data in _ore_inventory.values():
		total += ore_data["count"]
	return total

#endregion
