extends Control

var button_hover_tween: Tween
var selected_button: Button = null
var previous_button: Button = null
var levels_scene: String = "res://Scenes/UI/Levels_picker.tscn"
var shop_scene: String = "res://Scenes/Player Upgrade System/skill_tree_new.tscn"

func _on_startbutton_focus_entered() -> void:
	set_selected_button(%Startbutton)
	await tween_button()

func _on_startbutton_focus_exited() -> void:
	reset_scale()

func _on_startbutton_mouse_entered() -> void:
	set_selected_button(%Startbutton)
	await tween_button()

func _on_startbutton_mouse_exited() -> void:
	reset_scale()

func _on_startbutton_pressed() -> void:
	SceneManager.switch_scene(levels_scene)

func _on_shop_button_focus_entered() -> void:
	set_selected_button(%ShopButton)
	await tween_button()

func _on_shop_button_focus_exited() -> void:
	reset_scale()

func _on_shop_button_mouse_entered() -> void:
	set_selected_button(%ShopButton)
	await tween_button()

func _on_shop_button_mouse_exited() -> void:
	reset_scale()

func _on_shop_button_pressed() -> void:
	SceneManager.switch_scene(shop_scene)


func _on_setting_button_focus_entered() -> void:
	set_selected_button(%SettingButton)
	await tween_button()

func _on_setting_button_focus_exited() -> void:
	reset_scale()

func _on_setting_button_mouse_entered() -> void:
	set_selected_button(%SettingButton)
	await tween_button()

func _on_setting_button_mouse_exited() -> void:
	reset_scale()


func set_selected_button(button) -> void:
	selected_button = button
	previous_button = selected_button

func tween_button():
	await get_tree().process_frame
#	previous_button.release_focus()
	button_hover_tween = get_node(".").create_tween()
	button_hover_tween.tween_property(selected_button, "scale", Vector2(1.1, 1.1), .2).set_ease(Tween.EASE_IN_OUT). set_trans(Tween.TRANS_LINEAR)
	previous_button = selected_button

func reset_scale() -> void:
	previous_button.release_focus()
	selected_button.scale = Vector2(1.0,1.0)
