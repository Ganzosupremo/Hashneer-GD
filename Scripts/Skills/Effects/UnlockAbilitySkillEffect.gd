class_name UnlockAbilitySkillEffect extends SkillEffect
## Gives the player an ability. The scene root must be a [BaseAbility], the player instances it
## when a level starts in a mode the skill works in.

@export var ability_scene: PackedScene
## Name shown in the details, the scene file name when empty.
@export var ability_name: String = ""


func apply(loadout: PlayerLoadout, _level: int) -> void:
	if ability_scene:
		loadout.add_ability(ability_scene)

func describe(_level: int) -> String:
	return "Unlocks the %s ability" % get_ability_name()

func get_ability_name() -> String:
	if ability_name != "":
		return ability_name
	if ability_scene:
		return ability_scene.resource_path.get_file().get_basename().capitalize()
	return "?"

func is_level_independent() -> bool:
	return true
