class_name StatSkillEffect extends SkillEffect
## Raises a player stat by a flat amount or a percentage per level.
##
## The stat names are the keys of [member PlayerStatsManager.base_stats]. A new stat needs its
## base value there, its name in the [code]@export_enum[/code] below and code that reads it with
## [method PlayerLoadout.get_stat].[br]
## [b]Reductions[/b] ([constant REDUCTION_STATS]) have base 0 and use flat values: 0.04 per level
## is 4% less cooldown or damage taken. The player caps them, see [PlayerController].

@export_enum("Health", "Speed", "Damage", "Fire Rate", "Ability Cooldown", "Special Cooldown", "Damage Reduction", "Fiat Gain") var stat: String = "Health"
## Percentages are decimals: 0.1 is +10%. They multiply the base plus the flat bonuses.
@export var is_percentage: bool = false
## What the first level gives.
@export var value_per_level: float = 10.0
## Each next level gives this much times the previous one. 1.0 gives the same every level.
@export var value_multiplier: float = 1.0

## Stats that lower something: the flat value reads as a percentage with a minus sign.
const REDUCTION_STATS: Array[String] = ["Ability Cooldown", "Special Cooldown", "Damage Reduction"]


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
	if REDUCTION_STATS.has(stat):
		if stat == "Damage Reduction":
			return "Damage taken -%s%%" % _format_number(value * 100.0)
		return "%s -%s%%" % [stat, _format_number(value * 100.0)]
	if is_percentage:
		return "%s +%s%%" % [stat, _format_number(value * 100.0)]
	return "%s +%s" % [stat, _format_number(value)]

static func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % value
