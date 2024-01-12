extends Node2D
class_name UpdradesM


#const implements = [
#	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
#]

## Checks if the skill is already unlocked
func is_skill_unlocked(data) -> bool:
	return data["is_unlocked"]

func get_skill_power(skill_name: String) -> float:
	if SaveSystem.has(skill_name) == false: return 0.0
	
	var data = SaveSystem.get_var(skill_name)
	if is_skill_unlocked(data):
		return SaveSystem.get_var(skill_name)["current_power"]
	else: return 0.0

func get_skill(skill_name: String):
	if SaveSystem.has(skill_name):
		var data = SaveSystem.get_var(skill_name)
		if is_skill_unlocked(data):
			return data
	return null
