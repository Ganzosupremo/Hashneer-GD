class_name StatsResource extends Resource

enum StatType { PLAYER_SPEED, PLAYER_HEALTH, BULLET_SPEED, BULLET_DAMAGE, BULLET_SIZE }

@export var name: String = ""
@export var stat_type: StatType
@export var stat_power: float = 0.0


#func get_stat(looked_stat: StatType) -> float:
	#for info in stats:
		#if info.stat_type == looked_stat:
			#return info.stat_value
	#
	#printerr("NO STAT VALUE FOUND FOR {0} ON {1}".format([looked_stat, self.name]))
	#return 0.0
