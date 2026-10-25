extends Node
## GameStats keeps lifetime counters that survive new epochs, shown in the stats screen.
##
## Values for the current epoch (chain, wallet, inflation) are read directly from their systems,
## this only tracks totals that no other system keeps.

const SaveName: String = "game_stats"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

var stats: Dictionary = {
	"blocks_mined_by_player": 0,
	"blocks_lost_to_ai": 0,
	"btc_from_blocks": 0.0,
	"btc_from_fees": 0.0,
	"fiat_earned": 0.0,
	"halvings_seen": 0,
	"levels_played": 0,
	"deaths": 0,
	"play_time_seconds": 0.0,
}


func _ready() -> void:
	add_to_group("PersistentNodes")
	process_mode = Node.PROCESS_MODE_ALWAYS
	BitcoinNetwork.block_found.connect(_on_block_found)
	BitcoinNetwork.halving_occurred.connect(func(_subsidy: float) -> void: add("halvings_seen", 1))
	MiningFarm.fees_earned.connect(func(btc: float) -> void: add("btc_from_fees", btc))
	BitcoinWallet.fiat_added.connect(func(amount: float) -> void: add("fiat_earned", amount))
	GameManager.main_event_bus.level_completed.connect(_on_level_completed)

func _process(delta: float) -> void:
	if !get_tree().paused:
		stats.play_time_seconds += delta

## Adds [param amount] to the stat with the given name.
func add(stat: String, amount: float) -> void:
	stats[stat] = stats.get(stat, 0) + amount

func get_stat(stat: String) -> float:
	return stats.get(stat, 0)

func _on_block_found(block: BitcoinBlock) -> void:
	if block.miner == "AI":
		add("blocks_lost_to_ai", 1)
	else:
		add("blocks_mined_by_player", 1)
		add("btc_from_blocks", block.block_subsidy)

func _on_level_completed(args: MainEventBus.LevelCompletedArgs) -> void:
	add("levels_played", 1)
	if args.code == Constants.ERROR_404:
		add("deaths", 1)

func save_data() -> void:
	SaveSystem.set_var(SaveName, stats)

func load_data() -> void:
	if !SaveSystem.has(SaveName): return
	var data: Dictionary = SaveSystem.get_var(SaveName)
	for key in stats.keys():
		stats[key] = data.get(key, stats[key])
