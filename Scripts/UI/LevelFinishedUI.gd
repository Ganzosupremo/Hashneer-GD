class_name LevelCompletedUI extends Control

@export var item_drop_bus: ItemDropsBus
@export var main_event_bus: MainEventBus

@onready var title_label: AnimatedLabel = %Title
@onready var bg: Panel = %Panel
@onready var btc_gained_label: AnimatedLabel = %BTCGainedLabel
@onready var fiat_gained_label: AnimatedLabel = %FiatGainedLabel

@onready var skill_tree_scene: PackedScene = load("res://Scenes/SkillTreeSystem/SkillTree.tscn")

var fiat_gained_so_far: float = 0.0
var btc_gained_this_time: float = 0.0

func _ready() -> void:
	GameManager.player.get_health_node().zero_health.connect(_on_zero_health)
	main_event_bus.level_completed.connect(_on_level_completed)
	item_drop_bus.item_picked.connect(_on_item_picked)
	hide()

func _on_zero_health() -> void:
	GameManager.complete_level(Constants.ERROR_404)

func _on_level_completed(args: MainEventBus.LevelCompletedArgs) -> void:
	open_ui(args.code)

func open_ui(title: String) -> void:
	title_label.text = title
	btc_gained_label.text = Utils.format_currency(btc_gained_this_time, true)

	if FED.authorize_transaction(fiat_gained_so_far):
		fiat_gained_label.text = Utils.format_currency(fiat_gained_so_far, true)
	else:
		fiat_gained_label.text = "Transaction Denied"
	_open()
	save()

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
	var pickup: Resource = event.pickup.get_pickup_resource()
	
	if pickup is not CurrencyPickupResource: return
	
        var level_id: int = GameManager.get_current_level()
        var block: BitcoinBlock = BitcoinNetwork.get_block_by_id(level_id)
        match pickup.currency_type:
		CurrencyPickupResource.CURRENCY_TYPE.FIAT:
			fiat_gained_so_far += event.pickup.resource_count
		CurrencyPickupResource.CURRENCY_TYPE.BTC:
			event.pickup.resource_count = BitcoinNetwork.get_block_subsidy()
			btc_gained_this_time += event.pickup.resource_count
			
                        if GameManager.player_in_completed_level():
                                btc_gained_this_time = 0
                                GameManager.complete_level(Constants.ERROR_500)
                        elif block == null or block.miner == "Player":
                                GameManager.complete_level(Constants.ERROR_200)
                        else:
                                GameManager.complete_level(Constants.ERROR_401)
		CurrencyPickupResource.CURRENCY_TYPE.NONE:
			pass
