class_name SkillUpgrade
extends Object

var data: UpgradeData
var next_tier_nodes: Array

signal upgrade_maxed
signal level_changed(new_level:int, max_level:int)

func _init(_data: UpgradeData, _next_tier_nodes: Array = []) -> void:
    data = _data
    next_tier_nodes = _next_tier_nodes
    if data:
        data.upgrade_maxed.connect(_on_upgrade_maxed)
        data.upgrade_level_changed.connect(_on_level_changed)
        data.next_tier_unlocked.connect(_unlock_next_tier)

func purchase() -> bool:
    return UpgradeService.purchase_upgrade(data)

func _on_upgrade_maxed() -> void:
    upgrade_maxed.emit()

func _on_level_changed(new_level:int, max_level:int) -> void:
    level_changed.emit(new_level, max_level)

func _unlock_next_tier() -> void:
    for node in next_tier_nodes:
        if node.is_unlocked:
            continue
        node.unlock()
