class_name SkillRequirement extends Resource
## A skill that must reach a level before another one can be bought, see [member SkillDefinition.requirements].

## Drag the required skill's [code].tres[/code] here.
@export var skill: SkillDefinition
@export var min_level: int = 1


func is_met() -> bool:
	return skill != null and SkillProgress.get_level(skill.id) >= min_level

func _to_string() -> String:
	if skill == null:
		return "?"
	if skill.max_level <= 1:
		return skill.display_name
	return "%s level %d" % [skill.display_name, min_level]
