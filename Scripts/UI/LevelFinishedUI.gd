extends Control

@export var event_bus: ItemDropsBus

@onready var title_label: AnimatedLabel = %Title
@onready var bg: Panel = %Panel
@onready var btc_gained_label: AnimatedLabel = %BTCGainedLabel
@onready var fiat_gained_label: AnimatedLabel = %FiatGainedLabel

@onready var skill_tree_scene: PackedScene = load("res://Scenes/SkillTreeSystem/SkillTree.tscn")

var fiat_gained_so_far: float = 0.0
var btc_gained_this_time: float = 0.0

func _ready() -> void:
	GameManager.player.get_health_node().zero_health.connect(_on_zero_health)
	# GameManager.current_quadrant_builder.quadrant_hitted.connect(_on_quadrant_hitted)
	event_bus.item_picked.connect(_on_item_picked)
	GameManager.current_block_core.onBlockDestroyed.connect(_on_core_destroyed)
	BitcoinNetwork.coin_subsidy_issued.connect(_on_subsidy_issued)
	hide()

func _on_zero_health() -> void:
	open_ui(Constants.ERROR_404)

func _on_core_destroyed() -> void:
	var block: BitcoinBlock = BitcoinNetwork.get_block_by_id(GameManager.current_level)
	if GameManager.player_in_completed_level():
		open_ui(Constants.ERROR_500)
	elif block.miner == "Player":
		open_ui(Constants.ERROR_200)
	else:
		open_ui(Constants.ERROR_401)

func _on_quadrant_hitted(fiat_gained: float) -> void:
	fiat_gained_so_far += fiat_gained

func _on_subsidy_issued(subsidy: float) -> void:
	btc_gained_this_time += subsidy

func open_ui(title: String) -> void:
	title_label.text = title
	
	btc_gained_label.text = Utils.format_currency(btc_gained_this_time)
	fiat_gained_label.text = Utils.format_currency(fiat_gained_so_far)
	save()
	_open()

func _open() -> void:
	show()
	title_label.animate_label(0.05)
	btc_gained_label.animate_label(0.15)
	fiat_gained_label.animate_label(0.15)
	

func _on_menu_button_pressed() -> void:
	SceneManager.switch_scene_with_packed(skill_tree_scene)

func save():
	PersistenceDataManager.save_game()

func _on_item_picked(event : PickupEvent) -> void:
	print("Item picked up: {0}".format([event.pickup]))
	var pickup: Resource = event.pickup.get_pickup_resource()
	if pickup is CurrencyPickupResource:
		print_debug("Pick up is CurrencyPickupResource")
		match pickup.currency_type:
			CurrencyPickupResource.CURRENCY_TYPE.FIAT:
				var amount = pickup.amount
				pickup.amount = FED.get_fiat_subsidy()
				fiat_gained_so_far += pickup.amount
				print("Fiat added for UI: ", fiat_gained_so_far)
			CurrencyPickupResource.CURRENCY_TYPE.BTC:
				pickup.amount = BitcoinNetwork.calculate_block_subsidy()
				btc_gained_this_time += pickup.amount
				print("bitcoin added for UI: ")
			CurrencyPickupResource.CURRENCY_TYPE.NONE:
				pass

func _on_terminate_button_pressed() -> void:
	GameManager.game_terminated.emit()
	open_ui(Constants.ERROR_210)
