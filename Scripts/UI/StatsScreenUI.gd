class_name StatsScreenUI extends PanelContainer
## Stats screen opened from the skill tree: the state of the timechain, the economy, the farm
## and the lifetime totals from [GameStats].
##
## The layout lives in [code]Scenes/UI/StatsScreenUI.tscn[/code], instanced by the skill tree scene.
## Every value label has a unique name ([code]%BlocksMinedValue[/code], ...) and is filled in [method _refresh].


func open() -> void:
	_refresh()
	show()
	reset_size()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_OPEN_SOUND, AudioManager.DestinationAudioBus.SFX)

func close() -> void:
	hide()
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.LEVEL_SELECTOR_CLOSE_SOUND, AudioManager.DestinationAudioBus.SFX)

func _refresh() -> void:
	# Current epoch
	%BlocksMinedValue.text = "%d / %d" % [BitcoinNetwork.chain.size(), GameManager.game_levels.size()]
	%BlockSubsidyValue.text = "%s BTC" % Utils.format_btc(BitcoinNetwork.get_block_subsidy())
	%HalvingsValue.text = "%d (next in %d blocks)" % [BitcoinNetwork.get_halvings_count(), BitcoinNetwork.get_blocks_until_next_halving()]
	%BtcMinedValue.text = "%s / %s BTC" % [Utils.format_btc(BitcoinNetwork.get_total_bitcoins_in_circulation()), Utils.format_btc(BitcoinNetwork.TOTAL_COINS)]
	%BtcLostValue.text = "%s BTC" % Utils.format_btc(BitcoinNetwork.get_coins_lost())
	%LevelsUnlockedValue.text = "%d / %d" % [GameManager._levels_unlocked, GameManager.game_levels.size()]
	%WalletValue.text = "%s BTC  ·  $%s" % [Utils.format_btc(BitcoinWallet.get_bitcoin_balance()), Utils.format_currency(BitcoinWallet.get_fiat_balance(), true)]
	%BtcPriceValue.text = "$%s" % Utils.format_currency(BitcoinWallet.get_btc_price_in_fiat(), true)
	%InflationValue.text = "+%d%%/block (prices x%.2f)" % [roundi(FED.get_current_inflation_rate() * 100.0), FED.get_total_inflation()]
	%HashrateValue.text = "%s TH/s (%.1f%%)" % [Utils.format_currency(MiningFarm.get_hashrate(), true), MiningFarm.get_network_share() * 100.0]
	%FeesValue.text = "%s BTC/h" % Utils.format_btc(MiningFarm.get_fees_per_second() * 3600.0)
	%EpochValue.text = "%d  ·  %d HODL points" % [MiningFarm.epoch, MiningFarm.hodl_points]
	%AchievementsValue.text = "%d / %d" % [Achievements.get_unlocked_count(), Achievements.ACHIEVEMENTS.size()]

	# All time
	%BlocksMinedByYouValue.text = "%d" % GameStats.get_stat("blocks_mined_by_player")
	%BlocksLostToAiValue.text = "%d" % GameStats.get_stat("blocks_lost_to_ai")
	%BtcFromBlocksValue.text = "%s BTC" % Utils.format_btc(GameStats.get_stat("btc_from_blocks"))
	%BtcFromFeesValue.text = "%s BTC" % Utils.format_btc(GameStats.get_stat("btc_from_fees"))
	%FiatReceivedValue.text = "$%s" % Utils.format_currency(GameStats.get_stat("fiat_earned"), true)
	%HalvingsSurvivedValue.text = "%d" % GameStats.get_stat("halvings_seen")
	%LevelsPlayedValue.text = "%d (%d deaths)" % [GameStats.get_stat("levels_played"), GameStats.get_stat("deaths")]
	%PlayTimeValue.text = _format_time(GameStats.get_stat("play_time_seconds"))

func _format_time(seconds: float) -> String:
	var total: int = int(seconds)
	return "%dh %02dm" % [total / 3600, (total % 3600) / 60]

func _on_replay_tutorial_pressed() -> void:
	Tutorial.reset()
	close()
	Tutorial.show_once("skill_tree")
