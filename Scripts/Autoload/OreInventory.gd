extends Node
## Singleton that tracks collected ores

signal ore_added(ore_type: OreDetails.OreType, value: float)
signal ore_removed(ore_type: OreDetails.OreType, amount: int)
signal inventory_cleared()

## Dictionary mapping OreType → {count: int, total_value: float}
var _ores: Dictionary = {}

func _ready() -> void:
        _reset_inventory()

## Add ore to inventory
func add_ore(ore_type: OreDetails.OreType, value: float) -> void:
        if not _ores.has(ore_type):
                _ores[ore_type] = {"count": 0, "total_value": 0.0}
        
        _ores[ore_type]["count"] += 1
        _ores[ore_type]["total_value"] += value
        ore_added.emit(ore_type, value)
        
        # Debug print
        print("Collected %s ore! Total: %d (Value: %.1f)" % [
                OreDetails.OreType.keys()[ore_type],
                _ores[ore_type]["count"],
                _ores[ore_type]["total_value"]
        ])

## Get ore count by type
func get_ore_count(ore_type: OreDetails.OreType) -> int:
        if _ores.has(ore_type):
                return _ores[ore_type]["count"]
        return 0

## Get total value of specific ore type
func get_ore_value(ore_type: OreDetails.OreType) -> float:
        if _ores.has(ore_type):
                return _ores[ore_type]["total_value"]
        return 0.0

## Get total value of all ores
func get_total_value() -> float:
        var total = 0.0
        for ore_data in _ores.values():
                total += ore_data["total_value"]
        return total

## Get all ores data
func get_all_ores() -> Dictionary:
        return _ores.duplicate()

## Clear all ores (when selling at shop)
func clear_inventory() -> void:
        _ores.clear()
        _reset_inventory()
        inventory_cleared.emit()

## Remove specific amount of ore
func remove_ore(ore_type: OreDetails.OreType, amount: int) -> bool:
        if not _ores.has(ore_type):
                return false
        
        if _ores[ore_type]["count"] < amount:
                return false
        
        # Calculate value per ore
        var value_per_ore = 0.0
        if _ores[ore_type]["count"] > 0:
                value_per_ore = _ores[ore_type]["total_value"] / float(_ores[ore_type]["count"])
        
        # Decrement count and value
        _ores[ore_type]["count"] -= amount
        _ores[ore_type]["total_value"] -= value_per_ore * amount
        
        # Remove if empty
        if _ores[ore_type]["count"] <= 0:
                _ores.erase(ore_type)
        
        ore_removed.emit(ore_type, amount)
        return true

func _reset_inventory() -> void:
        for ore_type in OreDetails.OreType.values():
                _ores[ore_type] = {"count": 0, "total_value": 0.0}
