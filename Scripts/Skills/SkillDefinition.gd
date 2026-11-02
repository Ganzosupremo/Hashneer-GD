class_name SkillDefinition extends Resource
## One skill of the skill tree: what it costs, what it needs, the modes it works in and what it does.
##
## Every [code].tres[/code] with this script inside [constant SkillProgress.SKILLS_DIR] (subfolders
## included) is loaded on startup and shows up in the tree, nothing else has to be registered.
## Its place in the tree comes from [member branch] (column) and the depth of its [member requirements] (row).
## Only the level of each skill is saved, by [member id], see [SkillProgress].

@export_category("Identity")
## Unique and stable, it is the key of the saved level. Don't rename it once players have saves.
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
## Shown instead of [member icon] once the skill is maxed, optional.
@export var icon_maxed: Texture2D

@export_category("Tree")
## Column of the tree. A new branch only needs a new name here and in [constant SkillTreeView.BRANCH_ORDER].
@export_enum("Defense", "Offense", "Utility", "Weapons") var branch: String = "Defense"
## Order inside its branch, -1 puts it after its deepest requirement.
@export var tier: int = -1

@export_category("Game Modes")
## Modes where the effects apply. The skill is bought once and does nothing in the other modes.
@export_flags("Mining", "Waves") var modes: int = Constants.GameModeFlag.MINING | Constants.GameModeFlag.WAVES

@export_category("Requirements")
## Skills that must reach a level before this one can be bought. None means it is available from the start.
@export var requirements: Array[SkillRequirement] = []
## [code]false[/code]: any requirement is enough. [code]true[/code]: all of them are needed.
@export var requires_all: bool = false

@export_category("Effects")
@export var effects: Array[SkillEffect] = []

@export_category("Cost")
@export var max_level: int = 1
## Fiat price of the first level, it also grows with the FED inflation.
@export var cost_fiat_base: float = 10000.0
## Each level costs this much times the previous one.
@export var cost_fiat_multiplier: float = 1.2
## Bitcoin price of the first level, it also changes with the halvings.
@export var cost_btc_base: float = 1.0
@export var cost_btc_multiplier: float = 1.1

@export_category("Save Migration")
## Save key the old skill tree used for this skill, the level saved there is moved to [member id] once.
@export var legacy_save_key: String = ""


## [code]true[/code] if the effects apply in [param mode], a [enum Constants.GameModeFlag] or 0 for any mode.
func applies_in(mode: int) -> bool:
	return mode == 0 or (modes & mode) != 0

## Cost of the next level when the skill is at [param level], before inflation, halvings and events.
func get_base_cost(currency: Constants.CurrencyType, level: int) -> float:
	if currency == Constants.CurrencyType.BITCOIN:
		return cost_btc_base * pow(cost_btc_multiplier, level)
	return cost_fiat_base * pow(cost_fiat_multiplier, level)

## Names of the modes this skill works in, for the UI.
func get_mode_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for mode_name in Constants.GameModeFlag.keys():
		if modes & Constants.GameModeFlag[mode_name]:
			names.append(mode_name.capitalize())
	return names

func get_icon(maxed: bool = false) -> Texture2D:
	return icon_maxed if maxed and icon_maxed else icon

func _to_string() -> String:
	return "SkillDefinition(%s)" % id
