extends Control

@onready var title_label: AnimatedLabel = %Title
@onready var bg: Panel = %Panel
@onready var ai_miner: AIMiner = %MinerAI
@onready var btc_gained_label: AnimatedLabel = %BTCGainedLabel
@onready var fiat_gained_label: AnimatedLabel = %FiatGainedLabel

@onready var skill_tree_scene: PackedScene = preload("res://Scenes/SkillTreeSystem/SkillTree.tscn")
@onready var world_scene: PackedScene = preload("res://Scenes/BlockLevels/World.tscn")

var fiat_gained_so_far: float = 0.0
var btc_gained_this_time: float = 0.0

func _ready() -> void:
	GameManager.player.get_health_node().zero_health.connect(_on_zero_health)
	BitcoinNetwork.block_found.connect(_on_block_mined)
	GameManager.current_quadrant_builder.quadrant_hitted.connect(_on_quadrant_hitted)
	BitcoinNetwork.reward_issued.connect(_on_reward_issued)
	self.visible = false

func _on_zero_health() -> void:
	open_ui(Constants.ERROR_404)

func _on_block_mined(block: BitcoinBlock) -> void:
	open_ui(Constants.ERROR_200 if block.miner == "Player" else Constants.ERROR_401)

func _on_quadrant_hitted(fiat_gained: float) -> void:
	fiat_gained_so_far += fiat_gained

func _on_reward_issued(reward: float) -> void:
	btc_gained_this_time += reward

func open_ui(title: String) -> void:
	title_label.text = title
	
	btc_gained_label.text = "%.2f" % btc_gained_this_time
	fiat_gained_label.text = "%.2f" % fiat_gained_so_far
	_open()

func _open() -> void:
	self.visible = true
	title_label.animate_label(0.05)
	btc_gained_label.animate_label(0.15)
	fiat_gained_label.animate_label(0.15)

func _on_menu_button_pressed() -> void:
	#save()
	SceneManager.switch_scene_with_packed(skill_tree_scene)

func _on_retry_button_pressed() -> void:
	#save()
	SceneManager.switch_scene_with_packed(world_scene)

func save(to_disk: bool = false):
	PersistenceDataManager.save_game(to_disk)


func _on_terminate_button_pressed() -> void:
	ai_miner.stop_mining()
	open_ui(Constants.ERROR_210)
