extends PanelContainer
class_name SkillInfoWindow

@onready var title = $Margins/MainContainer/SkillTitle
@onready var desc_text = $Margins/MainContainer/SkillDesc
@onready var max_level_text = $Margins/MainContainer/SkillTitle/SkillMaxLevel
@onready var skill_cost_text = %FiatCost
@onready var btc_cost: Label = %BTCCost


var selected_skill_data: UpgradeData
var bitcoin_upgrade_data: UpgradeData

signal opened
signal closed

func _ready() -> void:
	scale = Vector2.ZERO

func set_info_window(fiat_upgrade: UpgradeData, bitcoin_upgrade: UpgradeData, title, description):
	selected_skill_data = fiat_upgrade
	bitcoin_upgrade_data = bitcoin_upgrade
	
	reset_ui()
	_update_window_ui(true)
	show()
	emit_signal("opened")
	
	await _tween_window()

func _tween_window():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2.ONE, 0.75).from_current()
	tween.tween_callback(func(): _reset_anchor_preset())
	
	await tween.finished

func _reset_anchor_preset():
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)

func _hide_info_window():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.75).from_current()
	
	await  tween.finished
	
	reset_ui()
	hide()
	emit_signal("closed")

func _update_window_ui(update_all: bool, _title:String = "", description: String = ""):
	if update_all:
		title.text = _title
		desc_text.text = description
		skill_cost_text.text = "%.2f" % selected_skill_data.upgrade_cost()
		btc_cost.text = "%.2f" % bitcoin_upgrade_data.upgrade_cost()
		max_level_text.text = str(selected_skill_data.upgrade_level) + "/" + str(selected_skill_data.upgrade_max_level)
	else:
		max_level_text.text = str(selected_skill_data.upgrade_level) + "/" + str(selected_skill_data.upgrade_max_level)
		btc_cost.text = "%.2f" % selected_skill_data.upgrade_cost()
		skill_cost_text.text = "%.2f" % selected_skill_data.upgrade_cost()

func reset_ui():
	title.text = ""
	desc_text.text = ""
	max_level_text.text = "0/0"

func _on_buy_button_pressed() -> void:
	selected_skill_data.buy_upgrade(false)
	#SkillsTree.get_instance().update_skill_stats(selected_skill_data)
	_update_window_ui(false)

func _on_buy_max_button_pressed() -> void:
	selected_skill_data.buy_max(false)
	#SkillsTree.get_instance().update_skill_stats(selected_skill_data)
	_update_window_ui(false)

func _on_btc_buy_button_pressed() -> void:
	bitcoin_upgrade_data.buy_upgrade(true)
	#SkillsTree.get_instance().update_skill_stats(selected_skill_data)
	_update_window_ui(false)

func _on_btc_buy_max_button_pressed() -> void:
	bitcoin_upgrade_data.buy_max(true)
		#SkillsTree.get_instance().update_skill_stats(selected_skill_data)
	_update_window_ui(false)

func save_game():
	PersistenceDataManager.save_game()

func _on_close_button_pressed() -> void:
	_hide_info_window()
