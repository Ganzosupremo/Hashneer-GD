class_name SkillTreeData extends Resource

@export var upgrades_data: Array = []
@export var skill_nodes_data_array: Array = []
@export var upgrades_data_dic: Dictionary = {}

func _init(data = null) -> void:
	if data != null:
		add_var_to_dic(data)
	
	upgrades_data = []
	skill_nodes_data_array = []


func add_var_to_dic(value):
	if !upgrades_data_dic.has(value.upgrade_name):
		upgrades_data_dic[value.upgrade_name] = value
