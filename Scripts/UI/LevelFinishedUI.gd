extends Control

@onready var title_label: Label = %Title
@onready var bg: Panel = %Panel
@onready var menu_button = %MenuButton
@onready var shop_button = %ShopButton

@onready var menu_scene: PackedScene = preload("res://Scenes/UI/Main_game_ui.tscn")
@onready var skill_tree_scene: PackedScene = preload("res://Scenes/PlayerUpgradeSystem/skill_tree_new.tscn")

func _ready() -> void:
	self.visible = false
	BlockCore.get_instance().core_mined.connect(on_core_mined)
	GameManager.player.health.zero_power.connect(on_zero_power)

func on_zero_power() -> void:
	init_ui("You DIED!", true)

func on_core_mined(title: String, _bg_color: Color) -> void:
	init_ui(title)

func init_ui(title: String, third_button: bool = false) -> void:
	self.title_label.text = title
	menu_button.disabled = true
	shop_button.disabled = true
	if third_button:
		%RetryButton.visible = true
		%RetryButton.disabled = true
	
	_open(third_button)

func _open(third_button: bool = false) -> void:
	self.visible = true
	if third_button:
		%RetryButton.visible = true
	tween_menu()

func tween_menu() -> void:
	var tween: Tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(%Panel, "position", Vector2(446, 174), 0.8).from_current().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(Engine,"time_scale",0.2, 1.0).from_current().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	
	await tween.finished
	
	menu_button.disabled = false
	shop_button.disabled = false
	%RetryButton.disabled = false

func _on_menu_button_pressed() -> void:
	Engine.time_scale = 1.0
	SceneManager.switch_scene_with_packed(menu_scene)

func _on_shop_button_pressed() -> void:
	Engine.time_scale = 1.0
	SceneManager.switch_scene_with_packed(skill_tree_scene)

func _on_retry_button_pressed() -> void:
	Engine.time_scale = 1.0
	SceneManager.switch_scene("res://Scenes/BlockLevels/block_genesis.tscn")
