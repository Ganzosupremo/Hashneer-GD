class_name ArmoryUpgradeData extends Resource
## This class is used to store data for upgrades in the Armory.
##
## It inherits from Resource to allow for easy serialization and editing in the Godot editor.
## It contains properties for the upgrade name, description, and cost.


@export var upgrade_type: Constants.ArmoryUpgradeType
@export var upgrade_name: String
@export var upgrade_description: String
@export var upgrade_levels: int = 3
@export var upgrade_power_per_level: float = 0.1
@export var base_cost: float = 50000.0
@export var cost_multiplier: float = 1.5
@export var requires_bitcoin: bool = false