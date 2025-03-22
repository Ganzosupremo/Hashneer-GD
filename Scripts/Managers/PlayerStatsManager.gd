extends Node2D

signal stats_updated(event: SkillTreeEventBus.SkillTreeStatEvent)

signal weapon_unlocked(event: SkillTreeEventBus.SkillTreeWeaponEvent)

signal ability_unlocked(event: SkillTreeEventBus.SkillTreeAbilityEvent)

@export var skill_tree_event_bus: SkillTreeEventBus
@export var weapon_details_dictionary: Dictionary = {}
## Base stats for the player.
var base_stats: Dictionary = {
	"Speed": 200.0,
	"Health": 300.0,
	"Damage": 1.0
}

## Accumulated bonuses from upgrades.
var upgrade_bonuses: Dictionary = {
	"Speed": 0.0,
	"Health": 0.0,
	"Damage": 0.0,
}

# Accumulated percentage bonuses (stored as decimals, e.g. 0.1 for 10%).
var percent_bonuses: Dictionary = {
	"Speed": 0.0,
	"Health": 0.0,
	"Damage": 0.0
}

## This dictionary will store the unlocked weapons.
var unlocked_weapons: Dictionary = {}

## This dictionary will store the unlocked abilities.
var unlocked_abilities: Dictionary = {}

const SaveName: String = "player_stats"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

func _ready() -> void:
	skill_tree_event_bus.stat_upgraded.connect(_on_stat_upgraded)
	skill_tree_event_bus.weapon_unlocked.connect(_on_weapon_unlocked)
	skill_tree_event_bus.ability_unlocked.connect(_on_ability_unlocked)

func _on_stat_upgraded(event: SkillTreeEventBus.SkillTreeStatEvent):
	add_upgrade_bonus(event.stat_name, event.upgrade_power, event.is_percentage, event)

func _on_weapon_unlocked(event: SkillTreeEventBus.SkillTreeWeaponEvent):
	unlock_weapon(event.weapon_id, event.weapon_resource, event)

func _on_ability_unlocked(event: SkillTreeEventBus.SkillTreeAbilityEvent):
	unlock_ability(event.ability_id, event.ability_scene, event)

## Called to add bonus when an upgrade is applied.
func add_upgrade_bonus(stat_name: String, bonus: float, is_percentage: bool, event: SkillTreeEventBus.SkillTreeStatEvent = null) -> void:
	if is_percentage:
		if !percent_bonuses.has(stat_name):
			percent_bonuses[stat_name] = bonus
			return
		percent_bonuses[stat_name] += bonus
	else:
		if !upgrade_bonuses.has(stat_name):
			upgrade_bonuses[stat_name] = bonus
			return
		upgrade_bonuses[stat_name] += bonus
	stats_updated.emit(event)

func unlock_weapon(weapon_id: String, weapon_resource: WeaponDetails, event: SkillTreeEventBus.SkillTreeWeaponEvent = null) -> void:
	unlocked_weapons[weapon_id] = weapon_resource
	weapon_unlocked.emit(event)

func unlock_ability(ability_id: String, ability_scene: PackedScene, event: SkillTreeEventBus.SkillTreeAbilityEvent = null) -> void:
	unlocked_abilities[ability_id] = ability_scene
	ability_unlocked.emit(event)

func get_unlocked_abilities() -> Dictionary:
	return unlocked_abilities

func get_unlocked_ability(ability_id: String) -> PackedScene:
	return unlocked_abilities[ability_id]

func get_unlocked_weapons() -> Dictionary:
	return unlocked_weapons

func get_weapon_details_from_dictionary(weapon_name: String) -> WeaponDetails:
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
		"unlocked_weapons": unlocked_weapons.keys(),
		"unlocked_abilities": unlocked_abilities.keys(),
	}

func load_data() -> void:
	if !SaveSystem.has(SaveName): return
	var data: Dictionary = SaveSystem.get_var(SaveName)
	upgrade_bonuses = data["upgrade_bonuses"]
	_load_saved_bonuses(upgrade_bonuses)
	# _load_unlocked_weapons(data["unlocked_weapons"])

func _load_saved_bonuses(data: Dictionary) -> void:
	for entry in data.keys():
		var event = SkillTreeEventBus.SkillTreeStatEvent.new(entry, data.get(entry, 0.0))
		stats_updated.emit(event)

func _load_unlocked_weapons(data: Array) -> void:
	for weapon_name in data:
		var weapon: WeaponDetails = get_weapon_details_from_dictionary(weapon_name)
		var event: SkillTreeEventBus.SkillTreeWeaponEvent = SkillTreeEventBus.SkillTreeWeaponEvent.new(weapon_name, weapon)
		unlock_weapon(weapon_name, weapon, event)
