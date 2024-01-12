extends PanelContainer
class_name SkillInfoWindow

@onready var title = $Margins/MainContainer/SkillTitle
@onready var desc_text = $Margins/MainContainer/SkillDesc
@onready var max_level_text = $Margins/MainContainer/SkillTitle/SkillMaxLevel
@onready var skill_cost_text = %FiatCost
@onready var btc_cost: Label = %BTCCost


var selected_skill_data: SkillUpgradeData

signal opened
signal closed

func _ready() -> void:
	scale = Vector2.ZERO

func set_info_window(data: SkillUpgradeData):
	selected_skill_data = data
	
	reset_ui()
	update_window_ui(true)
	show()
	emit_signal("opened")
	
	await tween_window()

func tween_window():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2.ONE, 0.75).from_current()
	tween.tween_callback(func(): reset_anchor_preset())
	
	await tween.finished

func reset_anchor_preset():
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)

func hide_info_window():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.75).from_current()
	
	await  tween.finished
	
	reset_ui()
	hide()
	emit_signal("closed")

func update_window_ui(update_all: bool):
	if update_all:
		title.text = selected_skill_data.upgrade_name
		desc_text.text = selected_skill_data.upgrade_description
		skill_cost_text.text = "%.2f" % selected_skill_data.upgrade_cost(false)
		btc_cost.text = "%.2f" % selected_skill_data.upgrade_cost(true)
		max_level_text.text = str(selected_skill_data.upgrade_level) + "/" + str(selected_skill_data.upgrade_max_level)
	else:
		max_level_text.text = str(selected_skill_data.upgrade_level) + "/" + str(selected_skill_data.upgrade_max_level)
		btc_cost.text = "%.2f" % selected_skill_data.upgrade_cost(true)
		skill_cost_text.text = "%.2f" % selected_skill_data.upgrade_cost(false)

func reset_ui():
	title.text = ""
	desc_text.text = ""
	max_level_text.text = "0/0"

func _on_buy_button_pressed() -> void:
	if selected_skill_data.upgrade_level < selected_skill_data.upgrade_max_level:
		selected_skill_data.buy_upgrade(false)
		SkillsTree.get_instance().update_skill_stats(selected_skill_data)
		update_window_ui(false)

func _on_buy_max_button_pressed() -> void:
	if selected_skill_data.upgrade_level < selected_skill_data.upgrade_max_level:
		selected_skill_data.buy_max(false)
		SkillsTree.get_instance().update_skill_stats(selected_skill_data)
		update_window_ui(false)

func _on_btc_buy_button_pressed() -> void:
	if selected_skill_data.upgrade_level < selected_skill_data.upgrade_max_level:
		selected_skill_data.buy_upgrade(true)
		SkillsTree.get_instance().update_skill_stats(selected_skill_data)
		update_window_ui(false)

func _on_btc_buy_max_button_pressed() -> void:
	if selected_skill_data.upgrade_level < selected_skill_data.upgrade_max_level:
		selected_skill_data.buy_max(true)
		SkillsTree.get_instance().update_skill_stats(selected_skill_data)
		update_window_ui(false)

func save_game():
	PersistenceDataManager.save_game()

func _on_close_button_pressed() -> void:
	hide_info_window()
