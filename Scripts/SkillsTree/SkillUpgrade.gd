class_name SkillUpgrade
extends Object

var data: UpgradeData
var next_tier_nodes: Array[SkillNode]

signal upgrade_maxed
signal level_changed(new_level:int, max_level:int)
signal update_ui()

func _init(_data: UpgradeData, _next_tier_nodes: Array = []) -> void:
	data = _data
	next_tier_nodes = _next_tier_nodes
	if data:
		data.update_ui.connect(_update_ui)
		data.upgrade_maxed.connect(_on_upgrade_maxed)
		data.upgrade_level_changed.connect(_on_level_changed)
		data.next_tier_unlocked.connect(_unlock_next_tier)

func apply_random_economic_event(_economic_event: EconomicEvent) -> void:
	if !data: return
	data.apply_random_economic_event(_economic_event)

func revert_economic_event_effects() -> void:
	if !data: return
	data.revert_economic_event_effects()

func purchase() -> bool:
	return UpgradeService.purchase_upgrade(data)

func _update_ui() -> void:
	update_ui.emit()

func _on_upgrade_maxed() -> void:
	upgrade_maxed.emit()

func _on_level_changed(new_level:int, max_level:int) -> void:
	level_changed.emit(new_level, max_level)

func _unlock_next_tier(_next_tier_nodes: Array[SkillNode]) -> void:
	if _next_tier_nodes != []:
		self.next_tier_nodes = _next_tier_nodes.duplicate()
	
	for node in self.next_tier_nodes:
		if node.is_unlocked:
			continue
		node.unlock()

func reset_next_tier_nodes_array() -> void:
	next_tier_nodes = []
	data.reset_next_tier_nodes()
