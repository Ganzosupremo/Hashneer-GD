extends Control

const SKILL_TREE_BITCOIN: PackedScene = preload("res://Scenes/SkillTreeSystem/SkillTreeBitcoin.tscn")
const SKILL_TREE_FIAT: PackedScene = preload("res://Scenes/SkillTreeSystem/SkillTreeFiat.tscn")



func _on_skill_tree_bitcoin_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(SKILL_TREE_BITCOIN)


func _on_skill_tree_fiat_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(SKILL_TREE_FIAT)
