class_name StatsScreenUI extends PanelContainer
## Stats screen opened from the skill tree: the state of the timechain, the economy, the farm
## and the lifetime totals from [GameStats].
##
## The screen is built in code and added by [SkillTreeManager].

const FONT_SIZE: int = 11

var _columns: Array[GridContainer] = []


func _ready() -> void:
	theme = preload("res://game_main_theme.tres")
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	_build()
	hide()

func open() -> void:
	_refresh()
	show()
	reset_size()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_OPEN_SOUND, AudioManager.DestinationAudioBus.SFX)

func close() -> void:
	hide()
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_CLOSE_SOUND, AudioManager.DestinationAudioBus.SFX)

func _build() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Stats"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_SIZE + 8)
	vbox.add_child(title)

	# Current epoch on the left, lifetime totals on the right
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)
	for i in 2:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 16)
		hbox.add_child(grid)
		_columns.append(grid)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	vbox.add_child(buttons)
	var replay: Button = Button.new()
	replay.text = "Replay tutorial"
	replay.pressed.connect(_on_replay_tutorial_pressed)
	buttons.add_child(replay)
	var close_button: Button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(close)
	buttons.add_child(close_button)

func _refresh() -> void:
	for grid in _columns:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()

	var mined: float = BitcoinNetwork.get_total_bitcoins_in_circulation()
	var rows: Array = [
		["Timechain", ""],
		["Blocks mined", "%d / %d" % [BitcoinNetwork.chain.size(), GameManager.game_levels.size()]],
		["Block subsidy", "%s BTC" % Utils.format_btc(BitcoinNetwork.get_block_subsidy())],
		["Halvings", "%d (next in %d blocks)" % [BitcoinNetwork.get_halvings_count(), BitcoinNetwork.get_blocks_until_next_halving()]],
		["BTC mined", "%s / %s BTC" % [Utils.format_btc(mined), Utils.format_btc(BitcoinNetwork.TOTAL_COINS)]],
		["BTC lost to the AI", "%s BTC" % Utils.format_btc(BitcoinNetwork.get_coins_lost())],
		["Levels unlocked", "%d / %d" % [GameManager._levels_unlocked, GameManager.game_levels.size()]],
		["Economy", ""],
		["Wallet", "%s BTC  ·  $%s" % [Utils.format_btc(BitcoinWallet.get_bitcoin_balance()), Utils.format_currency(BitcoinWallet.get_fiat_balance(), true)]],
		["BTC price", "$%s" % Utils.format_currency(BitcoinWallet.get_btc_price_in_fiat(), true)],
		["Inflation", "+%d%%/block (prices x%.2f)" % [roundi(FED.get_current_inflation_rate() * 100.0), FED.get_total_inflation()]],
		["Mining Farm", ""],
		["Hashrate", "%s TH/s (%.1f%%)" % [Utils.format_currency(MiningFarm.get_hashrate(), true), MiningFarm.get_network_share() * 100.0]],
		["Fees", "%s BTC/h" % Utils.format_btc(MiningFarm.get_fees_per_second() * 3600.0)],
		["Epoch", "%d  ·  %d HODL points" % [MiningFarm.epoch, MiningFarm.hodl_points]],
		["Achievements", "%d / %d" % [Achievements.get_unlocked_count(), Achievements.ACHIEVEMENTS.size()]],
	]
	var lifetime_rows: Array = [
		["All time", ""],
		["Blocks mined by you", "%d" % GameStats.get_stat("blocks_mined_by_player")],
		["Blocks lost to the AI", "%d" % GameStats.get_stat("blocks_lost_to_ai")],
		["BTC from blocks", "%s BTC" % Utils.format_btc(GameStats.get_stat("btc_from_blocks"))],
		["BTC from fees", "%s BTC" % Utils.format_btc(GameStats.get_stat("btc_from_fees"))],
		["Fiat received", "$%s" % Utils.format_currency(GameStats.get_stat("fiat_earned"), true)],
		["Halvings survived", "%d" % GameStats.get_stat("halvings_seen")],
		["Levels played", "%d (%d deaths)" % [GameStats.get_stat("levels_played"), GameStats.get_stat("deaths")]],
		["Play time", _format_time(GameStats.get_stat("play_time_seconds"))],
	]
	_add_rows(_columns[0], rows)
	_add_rows(_columns[1], lifetime_rows)

func _add_rows(grid: GridContainer, rows: Array) -> void:
	for row in rows:
		var name_label: Label = Label.new()
		name_label.text = row[0]
		var value_label: Label = Label.new()
		value_label.text = row[1]
		if row[1].is_empty():
			# Section header
			name_label.add_theme_font_size_override("font_size", FONT_SIZE + 3)
			name_label.modulate = Color(1.0, 0.75, 0.2)
		else:
			name_label.add_theme_font_size_override("font_size", FONT_SIZE)
			value_label.add_theme_font_size_override("font_size", FONT_SIZE)
		grid.add_child(name_label)
		grid.add_child(value_label)

func _format_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%dh %02dm" % [total / 3600, (total % 3600) / 60]

func _on_replay_tutorial_pressed() -> void:
	Tutorial.reset()
	close()
	Tutorial.show_once("skill_tree")
