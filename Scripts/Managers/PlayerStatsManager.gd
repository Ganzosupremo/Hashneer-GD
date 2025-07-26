extends Node2D

signal stats_updated(event: PlayerProgressEventBus.StatUpgradeEvent)

signal weapon_unlocked(event: PlayerProgressEventBus.WeaponUnlockEvent)

signal ability_unlocked(event: PlayerProgressEventBus.AbilityUnlockEvent)

@export var progress_event_bus: PlayerProgressEventBus
@export var weapon_details_dictionary: Dictionary = {
	5: preload("res://Resources/Weapons/Player/AK47.tres"),
	4: preload("res://Resources/Weapons/Player/AWPSniper.tres"),
	3: preload("res://Resources/Weapons/Player/MiniUzis.tres"),
	1: preload("res://Resources/Weapons/Player/Shotgun.tres"),
}
@export var ability_scenes_dictionary: Dictionary = {
	"Block Core Finder": preload("res://Scenes/Player/Abilities/BlockCoreFinder.tscn"),
	"Magnet": preload("res://Scenes/Player/Abilities/Magnet.tscn"),
	"Regenerate Health Over Time": preload("res://Scenes/Player/Abilities/RegenHealthOverTime.tscn"),
}
## Base stats for the player.
var base_stats: Dictionary = {
	"Speed": 150.0,
	"Health": 300.0,
	"Damage": 1.0
}

## Accumulated bonuses from upgrades.
var upgrade_bonuses: Dictionary = {
	"Speed": 0.0,
	"Health": 0.0,
	"Damage": 0.0,
}

## Accumulated percentage bonuses (stored as decimals, e.g. 0.1 for 10%).
var percent_bonuses: Dictionary = {
	"Speed": 0.0,
	"Health": 0.0,
	"Damage": 0.0
}

## This dictionary will store the unlocked weapons using [Constants.WeaponNames] as keys.
var unlocked_weapons: Dictionary = {}

## This dictionary will store the unlocked abilities using [Constants.AbilityNames] as keys.
var unlocked_abilities: Dictionary = {}

const SaveName: String = "player_stats"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	progress_event_bus.stat_upgraded.connect(_on_stat_upgraded)
	progress_event_bus.weapon_unlocked.connect(_on_weapon_unlocked)
	progress_event_bus.ability_unlocked.connect(_on_ability_unlocked)

func _on_stat_upgraded(event: PlayerProgressEventBus.StatUpgradeEvent):
	var stat_name: String= Utils.player_stat_type_to_string(event.stat_type)
	add_upgrade_bonus(stat_name, event.upgrade_power, event.is_percentage, event)

func _on_weapon_unlocked(event: PlayerProgressEventBus.WeaponUnlockEvent):
	unlock_weapon(event.weapon_id, event.weapon_resource, event)

func _on_ability_unlocked(event: PlayerProgressEventBus.AbilityUnlockEvent):
	unlock_ability(event.ability_id, event.ability_scene, event)

## Called to add bonus when an upgrade is applied.
func add_upgrade_bonus(stat_name: String, bonus: float, is_percentage: bool, event: PlayerProgressEventBus.StatUpgradeEvent = null) -> void:
	if is_percentage:
		if !percent_bonuses.has(stat_name):
			percent_bonuses[stat_name] = bonus
		else:
			percent_bonuses[stat_name] += bonus
	else:
		if !upgrade_bonuses.has(stat_name):
			upgrade_bonuses[stat_name] = bonus
		else:
			upgrade_bonuses[stat_name] += bonus
	stats_updated.emit(event)

func unlock_weapon(weapon_id: Constants.WeaponNames, weapon_resource: WeaponDetails, event: PlayerProgressEventBus.WeaponUnlockEvent = null) -> void:
	unlocked_weapons[weapon_id] = weapon_resource
	weapon_unlocked.emit(event)

func unlock_ability(ability_id: Constants.AbilityNames, ability_scene: PackedScene, event: PlayerProgressEventBus.AbilityUnlockEvent = null) -> void:
	unlocked_abilities[ability_id] = ability_scene
	ability_unlocked.emit(event)

func get_unlocked_abilities() -> Dictionary:
	return unlocked_abilities

func get_unlocked_ability(ability_id: Constants.AbilityNames) -> PackedScene:
	return unlocked_abilities[ability_id]

func get_unlocked_weapons() -> Dictionary:
	return unlocked_weapons

func get_weapon_details_from_dictionary(weapon_name: int) -> WeaponDetails:
	return weapon_details_dictionary.get(weapon_name, null)

## Returns the final value of the given stat.
func get_stat_final_value(stat_name: String) -> float:
	var base_value = base_stats.get(stat_name, 0.0)
	var bonus = upgrade_bonuses.get(stat_name, 0.0)
	var percent_bonus = percent_bonuses.get(stat_name, 0.0)
	return (base_value + bonus) * (1.0 + percent_bonus)

## Optionally, reset all upgrades.
func reset_upgrades() -> void:
	for key in upgrade_bonuses.keys():
		upgrade_bonuses[key] = 0.0
	stats_updated.emit()

func save_data() -> void:
	SaveSystem.set_var(SaveName, _build_save_data())

func _build_save_data() -> Dictionary:
		return {
			"upgrade_bonuses": upgrade_bonuses,
			"percent_bonuses": percent_bonuses,
			"unlocked_weapons": unlocked_weapons.keys(),
			"unlocked_abilities": unlocked_abilities.keys(),
		}

func load_data() -> void:
		if !SaveSystem.has(SaveName): return
		var data: Dictionary = SaveSystem.get_var(SaveName)
		upgrade_bonuses = data.get("upgrade_bonuses", upgrade_bonuses)
		percent_bonuses = data.get("percent_bonuses", percent_bonuses)
		_load_saved_bonuses(upgrade_bonuses, false)
		_load_saved_bonuses(percent_bonuses, true)
		_load_unlocked_weapons(data["unlocked_weapons"])
		_load_unlocked_abilities(data["unlocked_abilities"])

func _load_saved_bonuses(data: Dictionary, is_percentage: bool = false) -> void:
	for entry in data.keys():
		var stat_type := Utils.string_to_enum(entry, UpgradeData.StatType)
		var event = PlayerProgressEventBus.StatUpgradeEvent.new(stat_type, data.get(entry, 0.0), is_percentage)
		stats_updated.emit(event)

func _load_unlocked_weapons(data: Array) -> void:
	for weapon_enum in data:
		var weapon: WeaponDetails = get_weapon_details_from_dictionary(int(weapon_enum))
		var event: PlayerProgressEventBus.WeaponUnlockEvent = PlayerProgressEventBus.WeaponUnlockEvent.new(int(weapon_enum), weapon)
		unlock_weapon(int(weapon_enum), weapon, event)

func _load_unlocked_abilities(data: Array) -> void:
	for ability_enum in data:
		var ability_scene: PackedScene = ability_scenes_dictionary.get(Utils.ability_name_to_string(int(ability_enum)), null)
		var event: PlayerProgressEventBus.AbilityUnlockEvent = PlayerProgressEventBus.AbilityUnlockEvent.new(int(ability_enum), ability_scene)
		unlock_ability(int(ability_enum), ability_scene, event)
