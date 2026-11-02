class_name StatSkillEffect extends SkillEffect
## Raises a player stat by a flat amount or a percentage per level.
##
## The stat names are the keys of [member PlayerStatsManager.base_stats]. A new stat needs its
## base value there, its name in the [code]@export_enum[/code] below and code that reads it with
## [method PlayerLoadout.get_stat].

@export_enum("Health", "Speed", "Damage") var stat: String = "Health"
## Percentages are decimals: 0.1 is +10%. They multiply the base plus the flat bonuses.
@export var is_percentage: bool = false
## What the first level gives.
@export var value_per_level: float = 10.0
## Each next level gives this much times the previous one. 1.0 gives the same every level.
@export var value_multiplier: float = 1.0


func apply(loadout: PlayerLoadout, level: int) -> void:
	loadout.add_stat(stat, get_total_value(level), is_percentage)

## Total bonus after [param level] levels: the sum of [code]value_per_level * value_multiplier ^ (k - 1)[/code].
func get_total_value(level: int) -> float:
	var total: float = 0.0
	for k in level:
		total += value_per_level * pow(value_multiplier, k)
	return total

func describe(level: int) -> String:
	var value: float = get_total_value(level)
	if is_percentage:
		return "%s +%s%%" % [stat, _format_number(value * 100.0)]
	return "%s +%s" % [stat, _format_number(value)]

static func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % value
