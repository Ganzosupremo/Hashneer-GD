class_name TesterFeatureCatalog extends RefCounted
## Default features of the Feature Tester, grouped by the game mode they belong to.
##
## Enemies come from [constant WaveSpawner.ENEMY_SCENES], bosses from every level's
## [member LevelBuilderArgs.boss_scenes], weapons and abilities from [code]PlayerStatsManager[/code].
## Adding content there is enough for it to show up here.[br]
## For a new kind of feature add a function like the ones below and call it from [method register_defaults].

const MINING: Array[StringName] = [TesterFeature.MINING]
const WAVES: Array[StringName] = [TesterFeature.WAVES]
const MENU: Array[StringName] = [TesterFeature.MENU]
const ALL: Array[StringName] = []

## Abilities that only work in some modes, by their key in [code]PlayerStatsManager.ability_scenes_dictionary[/code].
const ABILITY_MODES: Dictionary = {
	"Block Core Finder": MINING,
}

const FIAT_STEP: float = 100000.0
const BITCOIN_STEP: float = 1.0
const SPAWN_DISTANCE: Vector2 = Vector2(250.0, 450.0)


static func register_defaults(tester: Node) -> void:
	_register_player(tester)
	_register_weapons(tester)
	_register_abilities(tester)
	_register_currency(tester)
	_register_mining(tester)
	_register_enemies(tester)
	_register_bosses(tester)
	_register_waves(tester)
	_register_menus(tester)

#region Features

static func _register_player(tester: Node) -> void:
	tester.add_toggle("Player", "God Mode", TesterFeature.GAMEPLAY,
		func() -> bool: return _get_player() != null and _get_player().get_health_node().invincible,
		func(on: bool) -> void:
			if _require_player(tester):
				_get_player().get_health_node().invincible = on,
		"The player takes no damage")
	tester.add_action("Player", "Full Heal", TesterFeature.GAMEPLAY, func() -> void:
		if _require_player(tester):
			var health: HealthComponent = _get_player().get_health_node()
			health.heal(health.get_max_health()))
	for time_scale in [0.5, 1.0, 2.0]:
		tester.add_action("Player", "Game Speed x%s" % time_scale, TesterFeature.GAMEPLAY, func() -> void:
			Engine.time_scale = time_scale)

static func _register_weapons(tester: Node) -> void:
	var weapons: Array[WeaponDetails] = []
	if GameManager.player_details and GameManager.player_details.initial_weapon:
		weapons.append(GameManager.player_details.initial_weapon)
	for weapon in PlayerStatsManager.weapon_details_dictionary.values():
		if weapon and not weapons.has(weapon):
			weapons.append(weapon)

	for weapon in weapons:
		tester.add_action("Weapons", _weapon_label(weapon), TesterFeature.GAMEPLAY, func() -> void:
			if _require_player(tester):
				_get_player().get_active_weapon_node().equip_weapon(weapon),
			"Equips the weapon for this level only")
	tester.add_action("Weapons", "All Weapons", TesterFeature.GAMEPLAY, func() -> void:
		if _require_player(tester):
			for weapon in weapons:
				_get_player().get_active_weapon_node().equip_weapon(weapon)
			tester.report("%d weapons added, switch with the mouse wheel" % weapons.size()))

static func _register_abilities(tester: Node) -> void:
	for ability_key in PlayerStatsManager.ability_scenes_dictionary:
		var scene: PackedScene = PlayerStatsManager.ability_scenes_dictionary[ability_key]
		if not _is_ability_scene(scene):
			continue
		var modes: Array = ABILITY_MODES.get(ability_key, TesterFeature.GAMEPLAY)
		tester.add_action("Abilities", ability_key, modes, func() -> void:
			if _require_player(tester):
				_give_ability(tester, ability_key, scene),
			"Enables the ability for this level only")

static func _register_currency(tester: Node) -> void:
	tester.add_action("Currency (saved)", "+%d Fiat" % FIAT_STEP, ALL, func() -> void:
		BitcoinWallet.add_fiat(FIAT_STEP * tester.get_quantity()),
		"Multiplied by Quantity. It is saved like normal earnings")
	tester.add_action("Currency (saved)", "+%d BTC" % BITCOIN_STEP, ALL, func() -> void:
		BitcoinWallet.add_bitcoin(BITCOIN_STEP * tester.get_quantity()),
		"Multiplied by Quantity. It is saved like normal earnings")

static func _register_mining(tester: Node) -> void:
	tester.add_action("Block", "Mine Block Now", MINING, func() -> void:
		var builder: QuadrantBuilder = GameManager._current_quadrant_builder
		if not is_instance_valid(builder) or builder.block_core.destroyed:
			tester.report("The block core is already destroyed")
			return
		builder.fracture_block_core(INF, "Player", true),
		"Destroys the block core as if the player mined it")
	tester.add_action("Block", "Go To Block Core", MINING, func() -> void:
		var core: BlockCore = GameManager._current_block_core
		if _require_player(tester) and is_instance_valid(core):
			_get_player().global_position = core.global_position + Vector2(0.0, -150.0)
			_get_player().velocity = Vector2.ZERO)
	tester.add_toggle("AI Miner", "Freeze AI Timer", MINING,
		func() -> bool: return _get_ai_miner() != null and _get_ai_miner().ai_timer.paused,
		func(on: bool) -> void:
			if _get_ai_miner():
				_get_ai_miner().ai_timer.paused = on)
	tester.add_action("AI Miner", "+60 s AI Timer", MINING, func() -> void:
		var ai: AIMiner = _get_ai_miner()
		if ai and not ai.ai_timer.is_stopped():
			ai.ai_timer.start(ai.ai_timer.time_left + 60.0))
	tester.add_action("AI Miner", "AI Mines The Block", MINING, func() -> void:
		var ai: AIMiner = _get_ai_miner()
		if ai and not ai.ai_timer.is_stopped():
			ai.ai_timer.paused = false
			ai.ai_timer.start(0.1),
		"Tests losing the block to the AI")

static func _register_enemies(tester: Node) -> void:
	for enemy_name in WaveSpawner.ENEMY_SCENES:
		var scene: PackedScene = WaveSpawner.ENEMY_SCENES[enemy_name]
		tester.add_action("Enemies", enemy_name, WAVES, func() -> void:
			_spawn_enemies(tester, scene, tester.get_quantity()),
			"Spawns near the player, multiplied by Quantity")

static func _register_bosses(tester: Node) -> void:
	var bosses: Array[PackedScene] = [WaveSpawner.BOSS_SCENE]
	for level in GameManager.game_levels:
		for boss_scene in level.boss_scenes:
			if boss_scene and not bosses.has(boss_scene):
				bosses.append(boss_scene)

	for boss_scene in bosses:
		tester.add_action("Bosses", boss_scene.resource_path.get_file().get_basename().capitalize(), WAVES, func() -> void:
			_spawn_enemies(tester, boss_scene, 1),
			"Spawns the boss near the player, outside the level's boss flow")

static func _register_waves(tester: Node) -> void:
	tester.add_action("Waves", "Next Wave", WAVES, func() -> void:
		var spawner: WaveSpawner = _get_tree().get_first_node_in_group("WaveSpawner")
		if spawner:
			spawner.start_next_wave())
	tester.add_action("Waves", "Spawn Level Boss", WAVES, func() -> void:
		var mode: WavesGameMode = _get_tree().current_scene as WavesGameMode
		if mode and not mode.force_next_boss():
			tester.report("A boss is already active"),
		"Spawns the next boss like reaching the kill goal, its Bitcoin drop completes the level")
	tester.add_action("Waves", "Kill All Enemies", WAVES, func() -> void:
		var killed: int = 0
		for enemy in _get_tree().get_first_node_in_group("Enemies").get_children():
			if enemy is BaseEnemy and not enemy.is_queued_for_deletion():
				enemy.kill()
				killed += 1
		tester.report("%d enemies killed" % killed),
		"Counts as kills, bosses included")

static func _register_menus(tester: Node) -> void:
	tester.add_action("Progress (saved)", "Unlock All Levels", MENU, func() -> void:
		GameManager._levels_unlocked = GameManager.game_levels.size()
		tester.report("All levels unlocked, reopen the level selector"))

#endregion

#region Helpers

static func _get_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

static func _get_player() -> PlayerController:
	var player: PlayerController = GameManager._player
	return player if is_instance_valid(player) else null

static func _require_player(tester: Node) -> bool:
	if _get_player() == null:
		tester.report("No player in this scene")
		return false
	return true

static func _get_ai_miner() -> AIMiner:
	var scene: Node = _get_tree().current_scene
	return scene.get_node_or_null("MinerAI") as AIMiner if scene else null

static func _weapon_label(weapon: WeaponDetails) -> String:
	if weapon.weapon_name != "":
		return weapon.weapon_name
	return weapon.resource_path.get_file().get_basename().capitalize()

## Abilities the player can hold must be [BaseAbility] scenes, the Shield is a component instead.
static func _is_ability_scene(scene: PackedScene) -> bool:
	if scene == null:
		return false
	var probe: Node = scene.instantiate()
	var is_ability: bool = probe is BaseAbility
	probe.free()
	return is_ability

static func _give_ability(tester: Node, ability_key: String, scene: PackedScene) -> void:
	var player: PlayerController = _get_player()
	for ability in player.abilities:
		if is_instance_valid(ability) and ability.scene_file_path == scene.resource_path:
			tester.report("%s is already active" % ability_key)
			return
	var ability: BaseAbility = scene.instantiate()
	player.add_child(ability)
	player.abilities.append(ability)
	ability.enable()

static func _spawn_enemies(tester: Node, scene: PackedScene, count: int) -> void:
	var spawner: WaveSpawner = _get_tree().get_first_node_in_group("WaveSpawner")
	if spawner == null or not _require_player(tester):
		return
	var map_rect: Rect2 = WavesGameMode.get_world_map_rect()
	for i in count:
		var offset: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(SPAWN_DISTANCE.x, SPAWN_DISTANCE.y)
		var pos: Vector2 = (_get_player().global_position + offset).clamp(map_rect.position, map_rect.end)
		spawner.spawn_extra_enemy(scene.instantiate(), pos)

#endregion
