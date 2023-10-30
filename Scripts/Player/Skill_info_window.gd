extends PanelContainer
class_name SkillInfoWindow

@onready var title = $Margins/MainContainer/SkillTitle
@onready var desc_text = $Margins/MainContainer/SkillDesc
@onready var max_level_text = $Margins/MainContainer/SkillTitle/SkillMaxLevel

var selected_skill: SkillNode
var skill_level: int
var skill_max_level:int

func _ready() -> void:
	scale = Vector2.ZERO

func set_info_window(skill: SkillNode):
	selected_skill = skill
	skill_level = selected_skill.upgrade_data.upgrade_level
	skill_max_level = selected_skill.upgrade_data.upgrade_max_level
	
	reset_ui()
	update_window_ui(true)
	show()
	
	await tween_window()

func tween_window():
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 1.0).from_current().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(func(): reset_anchor_preset())
	
	await tween.finished

func reset_anchor_preset():
	set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	scale = Vector2(1.0,1.0)

func hide_info_window():
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 1.0).from_current().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)
	
	await  tween.finished
	
	reset_ui()
	hide()

func update_window_ui(update_all: bool):
	if update_all:
		title.text = selected_skill.upgrade_data.upgrade_name
		desc_text.text = selected_skill.upgrade_data.upgrade_description
		max_level_text.text = str(selected_skill.upgrade_data.upgrade_level) + "/" + str(selected_skill.upgrade_data.upgrade_max_level)
	else:
		max_level_text.text = str(selected_skill.upgrade_data.upgrade_level) + "/" + str(selected_skill.upgrade_data.upgrade_max_level)

func reset_ui():
	title.text = ""
	desc_text.text = ""
	max_level_text.text = "0/0"

func _on_buy_button_pressed() -> void:
		if selected_skill.upgrade_data.upgrade_level >= selected_skill.upgrade_data.upgrade_max_level: return
		
		if UpgradesManager.currency >= selected_skill.upgrade_data.upgrade_cost():
			UpgradesManager.currency -= selected_skill.upgrade_data.upgrade_cost()
			print("Currency Left: %s" % UpgradesManager.currency)
			print("Price: %s" % selected_skill.upgrade_data.upgrade_cost())
			UpgradesManager.update_skill_stats(selected_skill.upgrade_data)
			
			skill_level = selected_skill.upgrade_data.upgrade_level
			selected_skill.upgrade_data.upgrade_level = min(skill_level+1, skill_max_level)
			update_window_ui(false)
			
			if skill_level % 3 == 1: selected_skill.unlock_next_tier()

func _on_buy_max_button_pressed() -> void:
	print(selected_skill)


func _on_close_button_pressed() -> void:
	hide_info_window()
