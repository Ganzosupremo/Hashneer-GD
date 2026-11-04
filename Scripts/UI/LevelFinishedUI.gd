class_name LevelCompletedUI extends Control

@export var item_drop_bus: ItemDropsBus
@export var main_event_bus: MainEventBus
## Picking up Bitcoin ends the level. Waves mode turns it off: the run goes on to the next block.
@export var end_level_on_bitcoin: bool = true

@onready var title_label: AnimatedLabel = %Title
@onready var btc_gained_label: AnimatedLabel = %BTCGainedLabel
@onready var fiat_gained_label: AnimatedLabel = %FiatGainedLabel

var fiat_gained_so_far: float = 0.0
var btc_gained_this_time: float = 0.0
var _opened: bool = false
## Height -> subsidy of the blocks the player mined in this run and hasn't been counted yet
var _blocks_mined_this_run: Dictionary = {}

func _ready() -> void:
	var player := GameManager.get_player()
	if player != null:
		player.get_health_node().zero_health.connect(_on_zero_health)
	main_event_bus.level_completed.connect(_on_level_completed)
	item_drop_bus.item_picked.connect(_on_item_picked)
	BitcoinNetwork.block_found.connect(_on_block_found)
	hide()

func _on_zero_health() -> void:
	if _opened: return
	GameManager.complete_level(Constants.ERROR_404)

func _on_level_completed(args: MainEventBus.LevelCompletedArgs) -> void:
	open_ui(args.code)

func open_ui(title: String) -> void:
	if _opened: return
	_opened = true
	title_label.text = title
	btc_gained_label.text = Utils.format_btc(btc_gained_this_time)

	if FED.authorize_transaction(fiat_gained_so_far):
		fiat_gained_label.text = Utils.format_currency(fiat_gained_so_far, true)
	else:
		fiat_gained_label.text = "Transaction Denied"
	_open()
	save()

func _on_block_found(block: BitcoinBlock) -> void:
	if block.miner == "Player":
		_blocks_mined_this_run[block.height] = block.block_subsidy

func _open() -> void:
	show()
	title_label.animate_label(0.05)
	btc_gained_label.animate_label(0.15)
	fiat_gained_label.animate_label(0.15)
	
func _on_menu_button_pressed() -> void:
	SceneManager.switch_scene_with_enum(SceneManager.MainScenes.SKILL_TREE)

func save():
	PersistenceDataManager.save_game()

func _on_item_picked(event : PickupEvent) -> void:
	var pickup: Resource = event.pickup.get_pickup_resource()
	
	if pickup is not CurrencyPickupResource: return
	
	var level_id: int = GameManager.get_current_level()
	var block: BitcoinBlock = BitcoinNetwork.get_block_by_id(level_id)
	match pickup.currency_type:
		Constants.CurrencyType.FIAT:
			fiat_gained_so_far += event.pickup.resource_count
		Constants.CurrencyType.BITCOIN:
			if !end_level_on_bitcoin:
				# Only blocks the player mined in this run pay, each one once. Replayed blocks don't.
				if block != null and _blocks_mined_this_run.has(block.height):
					event.pickup.resource_count = _blocks_mined_this_run[block.height]
					btc_gained_this_time += event.pickup.resource_count
					_blocks_mined_this_run.erase(block.height)
				return
			event.pickup.resource_count = BitcoinNetwork.get_block_subsidy()
			btc_gained_this_time += event.pickup.resource_count
			
			if GameManager.player_in_completed_level():
				btc_gained_this_time = 0
				GameManager.complete_level(Constants.ERROR_500)
				AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_COMPLETED_NEGATIVE_SOUND_T1, AudioManager.DestinationAudioBus.SFX)				
			elif block == null or block.miner == "Player":
				GameManager.complete_level(Constants.ERROR_200)
				AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_COMPLETED_SOUND, AudioManager.DestinationAudioBus.SFX)
			else:
				GameManager.complete_level(Constants.ERROR_401)
				AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_COMPLETED_NEGATIVE_SOUND_T2, AudioManager.DestinationAudioBus.SFX)
		# No action needed for NONE type
		_:
			pass
