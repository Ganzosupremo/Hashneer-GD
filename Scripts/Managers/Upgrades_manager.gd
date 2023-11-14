extends Node2D
class_name UpdradesM

@export var currency: float = 10000.0

var upgrades: Dictionary = {
	"Copper_bullets_upgrade": {
		"is_upgrade":false,
		"unlocked": false,
		"level": 0,
		"power": 0.0
		},
	"Silver_bullets_upgrade": {
		"is_upgrade":false,
		"unlocked": false,
		"level": 0,
		"power": 0.0
		},
	"Gold_bullets_upgrade": {
		"is_upgrade":false,
		"unlocked": false,
		"level": 0,
		"power": 0.0
		},
}

func unlock_skill(data: String):
	if data in upgrades.keys():
		upgrades[data]["unlocked"] = true

func update_skill_stats(data: UpgradeBase):
	if data.id in upgrades.keys():
		if !is_skill_unlocked(data.id): unlock_skill(data.id)
		
		upgrades[data.id]["is_upgrade"] = data.is_upgrade
		upgrades[data.id]["level"] = data.upgrade_level
		upgrades[data.id]["power"] = data.upgrade_power()

## Checks if the skill is already unlocked
func is_skill_unlocked(data: String) -> bool:
	return upgrades[data]["unlocked"]

func u(skill_dic: Dictionary):
	upgrades.merge(skill_dic)
 
func save() -> Dictionary:
	return {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"upgrades": upgrades,
		"currency": currency,
	}
