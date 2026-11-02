extends Node
## Autoload that owns the skill tree: loads every [SkillDefinition], buys levels and saves them.
##
## The only saved state is the level of each skill (by [member SkillDefinition.id]) and the currency
## picked to pay. Stats, weapons and abilities are worked out from the levels with
## [method build_loadout] each time a game mode starts, so they are never saved twice.

## A skill level changed (bought, loaded or set by the Feature Tester).
signal skill_changed(skill_id: StringName, level: int)
## Many levels changed at once: a save was loaded or a new epoch started.
signal progress_reset()
## Prices changed: currency switch or economic event.
signal costs_changed()

## Folder with the skill resources, subfolders are scanned too.
const SKILLS_DIR: String = "res://Resources/Skills/"
const SAVE_NAME: String = "skill_progress"
const SAVE_VERSION: int = 1
## Save key of the old UpgradeService, it only kept the currency.
const LEGACY_CURRENCY_SAVE_NAME: String = "upgrade_service_data"

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

var current_currency: Constants.CurrencyType = Constants.CurrencyType.FIAT

var _skills: Dictionary = {}  # StringName id -> SkillDefinition
var _skill_list: Array[SkillDefinition] = []
var _levels: Dictionary = {}  # String id -> int
var _main_event_bus: MainEventBus
## Cost multipliers of the active economic event, 1.0 when there is none.
var _event_multiplier_fiat: float = 1.0
var _event_multiplier_btc: float = 1.0


func _ready() -> void:
	add_to_group("PersistentNodes")
	_main_event_bus = load("res://Resources/MainEventBus.tres")
	_main_event_bus.currency_changed.connect(_on_currency_changed)
	_main_event_bus.economy_event_picked.connect(_on_economy_event_picked)
	_main_event_bus.economy_event_expired.connect(_on_economy_event_expired)
	_load_catalog()

#region Catalog

func _load_catalog() -> void:
	_skills.clear()
	_skill_list.clear()
	_scan_dir(SKILLS_DIR)
	_skill_list.sort_custom(func(a: SkillDefinition, b: SkillDefinition) -> bool: return String(a.id) < String(b.id))
	DebugLogger.info("SkillProgress: %d skills loaded." % _skill_list.size())

func _scan_dir(path: String) -> void:
	# list_directory() also lists remapped resources in exported builds
	for entry in ResourceLoader.list_directory(path):
		if entry.ends_with("/"):
			_scan_dir(path + entry)
			continue
		if not (entry.ends_with(".tres") or entry.ends_with(".res")):
			continue
		var skill: SkillDefinition = load(path + entry) as SkillDefinition
		if skill == null:
			continue
		if skill.id == &"":
			skill.id = StringName(entry.get_basename().to_snake_case())
		if _skills.has(skill.id):
			push_error("SkillProgress: duplicated skill id '%s' in %s and %s" % [skill.id, _skills[skill.id].resource_path, skill.resource_path])
			continue
		_skills[skill.id] = skill
		_skill_list.append(skill)

func get_skill(skill_id: StringName) -> SkillDefinition:
	return _skills.get(skill_id, null)

func get_all_skills() -> Array[SkillDefinition]:
	return _skill_list.duplicate()

## Every weapon some skill can unlock, bought or not.
func get_all_weapons() -> Array[WeaponDetails]:
	var weapons: Array[WeaponDetails] = []
	for skill in _skill_list:
		for effect in skill.effects:
			var weapon_effect: UnlockWeaponSkillEffect = effect as UnlockWeaponSkillEffect
			if weapon_effect and weapon_effect.weapon and not weapons.has(weapon_effect.weapon):
				weapons.append(weapon_effect.weapon)
	return weapons

## Every ability some skill can unlock, as [code]{name, scene, modes}[/code] dictionaries.
func get_all_abilities() -> Array[Dictionary]:
	var abilities: Array[Dictionary] = []
	for skill in _skill_list:
		for effect in skill.effects:
			var ability_effect: UnlockAbilitySkillEffect = effect as UnlockAbilitySkillEffect
			if ability_effect and ability_effect.ability_scene:
				abilities.append({"name": ability_effect.get_ability_name(), "scene": ability_effect.ability_scene, "modes": skill.modes})
	return abilities

#endregion

#region State

func get_level(skill_id: StringName) -> int:
	return int(_levels.get(String(skill_id), 0))

func is_maxed(skill_id: StringName) -> bool:
	var skill: SkillDefinition = get_skill(skill_id)
	return skill != null and get_level(skill_id) >= skill.max_level

## [code]true[/code] when the requirements are met (or it already has levels).
func is_unlocked(skill_id: StringName) -> bool:
	var skill: SkillDefinition = get_skill(skill_id)
	if skill == null:
		return false
	if get_level(skill_id) > 0 or skill.requirements.is_empty():
		return true
	if skill.requires_all:
		return skill.requirements.all(func(req: SkillRequirement) -> bool: return req.is_met())
	return skill.requirements.any(func(req: SkillRequirement) -> bool: return req.is_met())

func get_cost(skill_id: StringName, currency: Constants.CurrencyType = current_currency) -> float:
	var skill: SkillDefinition = get_skill(skill_id)
	if skill == null:
		return INF
	var cost: float = skill.get_base_cost(currency, get_level(skill_id))
	if currency == Constants.CurrencyType.BITCOIN:
		return cost * BitcoinNetwork.get_deflation_multiplier() * _event_multiplier_btc
	return cost * FED.get_total_inflation() * _event_multiplier_fiat

func can_afford(skill_id: StringName, currency: Constants.CurrencyType = current_currency) -> bool:
	var balance: float = BitcoinWallet.get_bitcoin_balance() if currency == Constants.CurrencyType.BITCOIN else BitcoinWallet.get_fiat_balance()
	return balance >= get_cost(skill_id, currency)

func can_purchase(skill_id: StringName, currency: Constants.CurrencyType = current_currency) -> bool:
	return is_unlocked(skill_id) and not is_maxed(skill_id) and can_afford(skill_id, currency)

## Buys one level. Returns [code]false[/code] when it is locked, maxed or too expensive.
func purchase(skill_id: StringName, currency: Constants.CurrencyType = current_currency) -> bool:
	if not can_purchase(skill_id, currency):
		return false
	var cost: float = get_cost(skill_id, currency)
	var paid: bool = BitcoinWallet.spend_bitcoin(cost) if currency == Constants.CurrencyType.BITCOIN else BitcoinWallet.spend_fiat(cost)
	if not paid:
		return false
	_set_level(skill_id, get_level(skill_id) + 1)
	DebugLogger.log_skill_node_upgrade(String(skill_id), get_level(skill_id), cost)
	return true

## Buys as many levels as the balance allows, returns how many.
func purchase_max(skill_id: StringName, currency: Constants.CurrencyType = current_currency) -> int:
	var bought: int = 0
	while purchase(skill_id, currency):
		bought += 1
	return bought

## Sets a level without paying, for the Feature Tester.
func set_level(skill_id: StringName, level: int) -> void:
	var skill: SkillDefinition = get_skill(skill_id)
	if skill:
		_set_level(skill_id, clampi(level, 0, skill.max_level))

func _set_level(skill_id: StringName, level: int) -> void:
	if level <= 0:
		_levels.erase(String(skill_id))
	else:
		_levels[String(skill_id)] = level
	save_data()
	skill_changed.emit(skill_id, level)

## Removes every level, used by a new epoch.
func reset_all() -> void:
	_levels.clear()
	save_data()
	progress_reset.emit()

#endregion

#region Loadout

## Stats, weapons and abilities the bought skills give in [param mode]
## (a [enum Constants.GameModeFlag], 0 for every mode).
func build_loadout(mode: int = 0) -> PlayerLoadout:
	var loadout: PlayerLoadout = PlayerLoadout.new(mode)
	for skill in _skill_list:
		var level: int = get_level(skill.id)
		if level <= 0 or not skill.applies_in(mode):
			continue
		for effect in skill.effects:
			if effect:
				effect.apply(loadout, level)
	return loadout

## Game mode [param node] is playing in: the first ancestor (or the current scene) with a
## [code]get_skill_mode()[/code] function. 0 (every mode) when there is none.
func get_mode_for(node: Node) -> int:
	var current: Node = node
	while current:
		if current.has_method("get_skill_mode"):
			return current.get_skill_mode()
		current = current.get_parent()
	var scene: Node = get_tree().current_scene
	if scene and scene.has_method("get_skill_mode"):
		return scene.get_skill_mode()
	return 0

#endregion

#region Prices

func _on_currency_changed(currency: Constants.CurrencyType) -> void:
	if currency == current_currency:
		return
	current_currency = currency
	save_data()
	costs_changed.emit()

## The event sets a multiplier per currency, applying it again (e.g. on load) doesn't stack.
func _on_economy_event_picked(event: EconomicEvent) -> void:
	if event == null:
		return
	var multiplier: float = 1.0 + event.impact if _raises_prices(event) else max(1.0 - event.impact, 0.01)
	var currency: Constants.CurrencyType = event.currency_affected
	# Natural disasters hit both currencies
	if event.event_type == EconomicEvent.EventType.NATURAL_DISASTER:
		currency = Constants.CurrencyType.BOTH
	_event_multiplier_fiat = multiplier if currency != Constants.CurrencyType.BITCOIN else 1.0
	_event_multiplier_btc = multiplier if currency != Constants.CurrencyType.FIAT else 1.0
	costs_changed.emit()

func _on_economy_event_expired(_event: EconomicEvent) -> void:
	_event_multiplier_fiat = 1.0
	_event_multiplier_btc = 1.0
	costs_changed.emit()

func _raises_prices(event: EconomicEvent) -> bool:
	match event.event_type:
		EconomicEvent.EventType.DEFLATION, EconomicEvent.EventType.MARKET_BOOM, EconomicEvent.EventType.TECHNOLOGY_ADVANCEMENT:
			return false
	return true

#endregion

#region Persistence

func save_data() -> void:
	SaveSystem.set_var(SAVE_NAME, {
		"version": SAVE_VERSION,
		"currency": current_currency,
		"levels": _levels.duplicate(),
	})

func load_data() -> void:
	_levels.clear()
	if SaveSystem.has(SAVE_NAME):
		var data: Dictionary = SaveSystem.get_var(SAVE_NAME)
		current_currency = int(data.get("currency", Constants.CurrencyType.FIAT)) as Constants.CurrencyType
		var levels: Dictionary = data.get("levels", {})
		for key in levels:
			if _skills.has(StringName(key)):
				_levels[String(key)] = clampi(int(levels[key]), 0, get_skill(StringName(key)).max_level)
			else:
				# Kept so removing a skill file by mistake doesn't wipe its level
				_levels[String(key)] = int(levels[key])
	else:
		_migrate_legacy_save()
	progress_reset.emit()

## Saves from before this system kept one entry per skill node (by its save name)
## plus the summed stat bonuses and unlocks in "player_stats". Only the levels are needed now.
func _migrate_legacy_save() -> void:
	var migrated: int = 0
	for skill in _skill_list:
		var key: String = skill.legacy_save_key
		if key.is_empty() or not SaveSystem.has(key):
			continue
		var data = SaveSystem.get_var(key)
		if data is Dictionary:
			var level: int = clampi(int(data.get("upgrade_level", 0)), 0, skill.max_level)
			if level > 0:
				_levels[String(skill.id)] = level
				migrated += 1
		SaveSystem.delete(key)

	if SaveSystem.has(LEGACY_CURRENCY_SAVE_NAME):
		var data = SaveSystem.get_var(LEGACY_CURRENCY_SAVE_NAME)
		if data is Dictionary:
			current_currency = int(data.get("current_currency", Constants.CurrencyType.FIAT)) as Constants.CurrencyType
		SaveSystem.delete(LEGACY_CURRENCY_SAVE_NAME)

	save_data()
	if migrated > 0:
		DebugLogger.info("SkillProgress: migrated %d skill levels from the old skill tree save." % migrated)

#endregion
