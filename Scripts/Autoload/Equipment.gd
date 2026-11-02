extends Node
## The player's loadout: what they take into a game mode, chosen in the Armory.
##
## Each mode ([enum Constants.GameModeFlag]) has its own loadout:
## [constant MAX_WEAPONS] weapons, [constant MAX_PASSIVES] passive abilities and
## [constant MAX_ACTIVES] active ability.[br]
## What can be equipped comes from [method SkillProgress.build_loadout] (what the skills unlock in
## that mode) plus the starting weapons in [code]PlayerDetails.tres[/code]. Only ids are saved:
## weapon ids ([method WeaponDetails.get_upgrade_id]) and ability scene paths. Anything that is no
## longer available (new epoch, a skill reset) is dropped on read, and empty slots are filled with
## what is available, so a newly unlocked weapon or ability goes straight into a free slot.

signal equipment_changed(mode: int)

const MAX_WEAPONS: int = 2
const MAX_PASSIVES: int = 3
const MAX_ACTIVES: int = 1
const SAVE_NAME: String = "equipment"
const PLAYER_DETAILS: PlayerDetails = preload("res://Resources/Player/PlayerDetails.tres")
const MODES: Array[int] = [Constants.GameModeFlag.MINING, Constants.GameModeFlag.WAVES]

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

## Saved choices: {"<mode>": {"weapons": [id, ...], "passives": [path, ...], "active": path}}.
var _chosen: Dictionary = {}
## Ability scene path -> {name, description, kind, cooldown, icon}, read once per scene.
var _ability_info_cache: Dictionary = {}


func _ready() -> void:
	add_to_group("PersistentNodes")

#region Available

## Weapons that can be equipped in [param mode]: the starting ones plus the unlocked ones.
func get_available_weapons(mode: int, loadout: PlayerLoadout = null) -> Array[WeaponDetails]:
	if loadout == null:
		loadout = SkillProgress.build_loadout(mode)
	var weapons: Array[WeaponDetails] = []
	var candidates: Array = [PLAYER_DETAILS.initial_weapon]
	candidates.append_array(PLAYER_DETAILS.weapons_array)
	candidates.append_array(loadout.weapons)
	for weapon in candidates:
		if weapon is WeaponDetails and !weapons.has(weapon):
			weapons.append(weapon)
	return weapons

## Abilities of [param kind] ([enum BaseAbility.AbilityKind]) unlocked for [param mode].
func get_available_abilities(mode: int, kind: int, loadout: PlayerLoadout = null) -> Array[PackedScene]:
	if loadout == null:
		loadout = SkillProgress.build_loadout(mode)
	var scenes: Array[PackedScene] = []
	for scene in loadout.abilities:
		if scene and get_ability_info(scene).kind == kind:
			scenes.append(scene)
	return scenes

## Name, description, kind, cooldown and icon of an ability scene, without keeping it in the tree.
func get_ability_info(scene: PackedScene) -> Dictionary:
	if scene == null:
		return {}
	var path: String = scene.resource_path
	if _ability_info_cache.has(path):
		return _ability_info_cache[path]
	var info: Dictionary = {"name": path.get_file().get_basename().capitalize(), "description": "", "kind": BaseAbility.AbilityKind.PASSIVE, "cooldown": 0.0, "icon": null}
	var node: Node = scene.instantiate()
	if node is BaseAbility:
		info = {
			"name": node.ability_name,
			"description": node.ability_description,
			"kind": node.ability_kind,
			"cooldown": node.ability_cooldown,
			"icon": node.ability_icon,
		}
	node.free()
	_ability_info_cache[path] = info
	return info

#endregion

#region Equipped

## The weapons equipped for [param mode], first one is the one in hand at the start.
func get_equipped_weapons(mode: int, loadout: PlayerLoadout = null) -> Array[WeaponDetails]:
	var available: Array[WeaponDetails] = get_available_weapons(mode, loadout)
	var by_id: Dictionary = {}
	for weapon in available:
		by_id[weapon.get_upgrade_id()] = weapon
	var equipped: Array[WeaponDetails] = []
	for id in _get_mode_data(mode).get("weapons", []):
		if by_id.has(id) and !equipped.has(by_id[id]) and equipped.size() < MAX_WEAPONS:
			equipped.append(by_id[id])
	_fill(equipped, available, MAX_WEAPONS)
	return equipped

func get_equipped_passives(mode: int, loadout: PlayerLoadout = null) -> Array[PackedScene]:
	var available: Array[PackedScene] = get_available_abilities(mode, BaseAbility.AbilityKind.PASSIVE, loadout)
	var equipped: Array[PackedScene] = _pick_scenes(_get_mode_data(mode).get("passives", []), available, MAX_PASSIVES)
	_fill(equipped, available, MAX_PASSIVES)
	return equipped

## The equipped active ability for [param mode], or null.
func get_equipped_active(mode: int, loadout: PlayerLoadout = null) -> PackedScene:
	var available: Array[PackedScene] = get_available_abilities(mode, BaseAbility.AbilityKind.ACTIVE, loadout)
	var saved: String = _get_mode_data(mode).get("active", "")
	for scene in available:
		if scene.resource_path == saved:
			return scene
	return available[0] if !available.is_empty() else null

## Passives first, then the active one: every ability scene the player instances in [param mode].
func get_equipped_abilities(mode: int, loadout: PlayerLoadout = null) -> Array[PackedScene]:
	if loadout == null:
		loadout = SkillProgress.build_loadout(mode)
	var scenes: Array[PackedScene] = get_equipped_passives(mode, loadout)
	var active: PackedScene = get_equipped_active(mode, loadout)
	if active:
		scenes.append(active)
	return scenes

#endregion

#region Changing

## Puts [param weapon] in [param slot] (0 or 1). If it was in the other slot, the two swap.
func equip_weapon(mode: int, slot: int, weapon: WeaponDetails) -> void:
	var ids: Array = []
	for equipped in get_equipped_weapons(mode):
		ids.append(equipped.get_upgrade_id())
	_set_slot(ids, slot, weapon.get_upgrade_id(), MAX_WEAPONS)
	_get_mode_data(mode, true)["weapons"] = ids
	equipment_changed.emit(mode)

## Puts the passive [param scene] in [param slot] (0 to 2). If it was in another slot, they swap.
func equip_passive(mode: int, slot: int, scene: PackedScene) -> void:
	var paths: Array = []
	for equipped in get_equipped_passives(mode):
		paths.append(equipped.resource_path)
	_set_slot(paths, slot, scene.resource_path, MAX_PASSIVES)
	_get_mode_data(mode, true)["passives"] = paths
	equipment_changed.emit(mode)

func equip_active(mode: int, scene: PackedScene) -> void:
	_get_mode_data(mode, true)["active"] = scene.resource_path if scene else ""
	equipment_changed.emit(mode)

## Forgets every choice (new epoch): the slots fill again with what gets unlocked.
func reset() -> void:
	_chosen.clear()
	for mode in MODES:
		equipment_changed.emit(mode)

#endregion

#region Helpers

func _get_mode_data(mode: int, create: bool = false) -> Dictionary:
	var key: String = str(mode)
	if !_chosen.has(key):
		if !create:
			return {}
		_chosen[key] = {}
	return _chosen[key]

func _pick_scenes(paths: Array, available: Array[PackedScene], max_count: int) -> Array[PackedScene]:
	var picked: Array[PackedScene] = []
	for path in paths:
		for scene in available:
			if scene.resource_path == path and !picked.has(scene) and picked.size() < max_count:
				picked.append(scene)
	return picked

# Fills the free slots of [param equipped] with the first available items not equipped yet.
func _fill(equipped: Array, available: Array, max_count: int) -> void:
	for item in available:
		if equipped.size() >= max_count:
			return
		if !equipped.has(item):
			equipped.append(item)

# Writes [param value] in [param slot] of [param list], swapping with its old slot if it was there.
func _set_slot(list: Array, slot: int, value, max_count: int) -> void:
	slot = clampi(slot, 0, max_count - 1)
	var old_index: int = list.find(value)
	while list.size() <= slot:
		list.append(null)
	if old_index != -1 and old_index != slot:
		list[old_index] = list[slot]
	list[slot] = value
	# Drop the holes left by a swap with an empty slot
	while list.has(null):
		list.erase(null)

#endregion

#region Save

func save_data() -> void:
	SaveSystem.set_var(SAVE_NAME, _chosen)

func load_data() -> void:
	if !SaveSystem.has(SAVE_NAME):
		return
	var data = SaveSystem.get_var(SAVE_NAME)
	_chosen = data if data is Dictionary else {}

#endregion
