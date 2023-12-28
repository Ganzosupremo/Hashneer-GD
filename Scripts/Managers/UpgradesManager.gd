extends Node2D
class_name UpdradesM

@export var currency: float = 10_000.0

var upgrades: Dictionary = {}

const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]


func update_skill_stats(data: SkillUpgradeData):
	if data.id in upgrades.keys():
		if is_skill_unlocked(data.id) == false: unlock_skill(data.id)
		
		upgrades[data.id]["is_upgrade"] = data.is_upgrade
		upgrades[data.id]["level"] = data.upgrade_level
		upgrades[data.id]["power"] = data.upgrade_power()

## Checks if the skill is already unlocked
func is_skill_unlocked(data: String) -> bool:
	if upgrades.has(data):
		return upgrades[data]["unlocked"]
	else:
		return false

func unlock_skill(id: String):
	if id in upgrades.keys():
		upgrades[id]["unlocked"] = true

#func save() -> Dictionary:
#	var dic : Dictionary = {
#		"filename" : get_scene_file_path(),
#		"parent" : get_parent().get_path(),
#		"pos_x" : position.x,
#		"pos_y" : position.y,
#		"upgrades": upgrades,
#		"currency": currency,
#	}
#
#	return dic

func save_data(game_data: GameData):
	game_data.skill_node_data.upgrades_data.merge(upgrades)

func load_data(game_data: GameData):
	upgrades = game_data.skill_node_data.upgrades_data
	if game_data.skill_node_data.upgrades_data["id"] in upgrades.keys():
		if is_skill_unlocked(game_data.skill_node_data.upgrades_data.id) == true: 
			unlock_skill(game_data.skill_node_data.upgrades_data.id)
	
	
	
	
	
