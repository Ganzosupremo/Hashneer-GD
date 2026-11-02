class_name SkillEffect extends Resource
## Base of everything a skill does when it has levels, see [member SkillDefinition.effects].
##
## Effects never change the player directly: [method SkillProgress.build_loadout] calls
## [method apply] with the skill level on a fresh [PlayerLoadout] each time a game mode starts,
## so changing a value in a [code].tres[/code] also changes saves that already bought it.[br]
## For a new kind of effect extend this class, override [method apply] and [method describe],
## then add the effect to any skill in the inspector.


## Adds this effect to the loadout, [param level] is always 1 or more.
func apply(_loadout: PlayerLoadout, _level: int) -> void:
	pass

## Short text of what the effect gives at [param level], shown in the skill details.
func describe(_level: int) -> String:
	return ""

## [code]true[/code] when the effect is the same at every level (an unlock),
## the details panel then shows it once instead of current and next level.
func is_level_independent() -> bool:
	return false
