extends CanvasLayer
## Tutorial shows short step by step hints the first time the player reaches each part of the game.
##
## Each tutorial is a list of pages shown in a panel at the bottom of the screen. The game is paused
## while a page is shown, so the AI miner timer and the enemies wait for the player.
## Seen tutorials are saved, [method reset] makes them show again.
## The panel layout lives in [code]Scenes/UI/Tutorial.tscn[/code], which is the autoload.

const TUTORIALS: Dictionary = {
	"mining": [
		"Welcome to Hasheneer! Every level is a Bitcoin block waiting to be mined.",
		"Shoot the terrain to break it. Broken quadrants drop fiat money.",
		"Somewhere in the map is the Block Core. Destroy it and pick up the Bitcoin it drops to mine the block.",
		"Hurry! The AI miner is racing you. If its timer reaches zero it mines the block and you get nothing.",
		"Hitting the core hurts you too, keep an eye on your health. Good luck, miner!",
	],
	"waves": [
		"Waves mode: survive the enemy waves and fill the boss bar with kills.",
		"Defeat the boss and grab the Bitcoin it drops to mine this level's block. No Bitcoin? Another boss comes later.",
	],
	"skill_tree": [
		"This is your base. Spend fiat or Bitcoin on upgrades, use the toggle in the top left to switch currency.",
		"The FED prints money on every block: fiat prices keep rising. Bitcoin prices drop 25% on every halving.",
		"Use the exchange in the top left to trade fiat for Bitcoin, with a 5% fee.",
		"The Mining Farm (top right) earns Bitcoin fees over time, even while the game is closed. More hashrate also slows the AI down.",
		"Mine every block to start a New Epoch: you lose everything except HODL points, which boost you forever.",
		"Press Start Game to pick a level. Stats shows your progress and lets you replay this tutorial.",
	],
}

const SaveName: String = "tutorial"
const implements = [
	preload("res://Scripts/PersistenceDataSystem/IPersistenceData.gd")
]

var _seen: Dictionary = {}
var _pages: Array = []
var _page_index: int = 0
var _was_paused: bool = false

@onready var _panel: PanelContainer = %Panel
@onready var _label: Label = %PageLabel
@onready var _counter: Label = %CounterLabel
@onready var _next_button: Button = %NextButton


func _ready() -> void:
	add_to_group("PersistentNodes")

## Shows the tutorial with the given key if the player hasn't seen it yet.
func show_once(key: String) -> void:
	if _seen.has(key) or !TUTORIALS.has(key): return
	_seen[key] = true
	_pages = TUTORIALS[key]
	_page_index = 0
	_was_paused = get_tree().paused
	get_tree().paused = true
	_panel.show()
	_show_page()

## Makes every tutorial show again the next time its part of the game is reached.
func reset() -> void:
	_seen.clear()

func is_showing() -> bool:
	return _panel.visible

func _show_page() -> void:
	_label.text = _pages[_page_index]
	_counter.text = "%d/%d" % [_page_index + 1, _pages.size()]
	_next_button.text = "Got it" if _page_index == _pages.size() - 1 else "Next"

func _on_next_pressed() -> void:
	_page_index += 1
	if _page_index >= _pages.size():
		_close()
	else:
		_show_page()

func _close() -> void:
	_panel.hide()
	get_tree().paused = _was_paused

func save_data() -> void:
	SaveSystem.set_var(SaveName, {"seen": _seen.keys()})

func load_data() -> void:
	if !SaveSystem.has(SaveName): return
	_seen.clear()
	for key in SaveSystem.get_var(SaveName).get("seen", []):
		_seen[key] = true
