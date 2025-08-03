class_name IUpgradeable extends Resource
## Interface for items that can be upgraded in the Armory
##
## This interface defines the methods that any upgradeable item must implement.


## Returns a unique identifier for the upgrade.
## This should be overridden by the implementing class.
func get_upgrade_id() -> String:
    return "upgrade_id_not_implemented"

## Returns the name of the upgrade.
## This should be overridden by the implementing class.
func get_upgrade_name() -> String:
    return "upgrade_name_not_implemented"

## Returns the icon to display for the upgrade.
## This should be overridden by the implementing class.
func get_upgrade_description() -> String:
    return "upgrade_description_not_implemented"

## Returns the icon to display for the upgrade.
## This should be overridden by the implementing class.
func get_display_icon() -> Texture2D:
    return null

## Returns array of ArmoryUpgradeData that this item supports
func get_available_upgrades() -> Array[ArmoryUpgradeData]:
    return []

## Applies an upgrade effect to this item
func apply_upgrade(upgrade_type: Constants.ArmoryUpgradeType, level: int, upgrade_power_per_level: float) -> void:
    pass

## Returns current stats/properties to display in the armory
func get_current_stats() -> Dictionary:
    return {}