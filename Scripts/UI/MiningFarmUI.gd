class_name MiningFarmUI extends PanelContainer
## Skill tree panel for the [MiningFarm]: buy miners, see hashrate and fees, achievements and start a new epoch.
##
## The layout lives in [code]Scenes/UI/MiningFarmUI.tscn[/code], instanced by the skill tree scene.
## Each miner button in [code]%MinerButtons[/code] has a [code]miner_id[/code] metadata matching an id in [constant MiningFarm.MINERS].

## Emitted when the player confirms starting a new epoch.
signal new_epoch_requested()

@onready var _hashrate_label: Label = %HashrateLabel
@onready var _fees_label: Label = %FeesLabel
@onready var _achievements_label: Label = %AchievementsLabel
@onready var _epoch_label: Label = %EpochLabel
@onready var _epoch_button: Button = %EpochButton
@onready var _confirm_dialog: ConfirmationDialog = %ConfirmDialog

var _miner_buttons: Dictionary = {}


func _ready() -> void:
	for button in %MinerButtons.get_children():
		var miner_id: String = button.get_meta("miner_id", "")
		var miner: Dictionary = _find_miner(miner_id)
		if miner.is_empty():
			push_warning("MiningFarmUI: button %s has unknown miner_id '%s'" % [button.name, miner_id])
			continue
		button.tooltip_text = "+%s TH/s" % str(miner.hashrate)
		button.pressed.connect(_on_buy_miner_pressed.bind(miner_id))
		_miner_buttons[miner_id] = button

	BitcoinWallet.money_changed.connect(_on_state_changed)
	MiningFarm.miner_bought.connect(_on_state_changed)
	Achievements.achievement_unlocked.connect(_on_state_changed)
	_refresh()

func _exit_tree() -> void:
	BitcoinWallet.money_changed.disconnect(_on_state_changed)
	MiningFarm.miner_bought.disconnect(_on_state_changed)
	Achievements.achievement_unlocked.disconnect(_on_state_changed)

func _find_miner(miner_id: String) -> Dictionary:
	for miner in MiningFarm.MINERS:
		if miner.id == miner_id:
			return miner
	return {}

func _process(_delta: float) -> void:
	# Fees and the network share change every second, keep the numbers live
	_hashrate_label.text = "Hashrate: %s TH/s (%.1f%% of network)" % [Utils.format_currency(MiningFarm.get_hashrate(), true), MiningFarm.get_network_share() * 100.0]
	_fees_label.text = "Fees: %s BTC/h  ·  AI timer x%.2f" % [Utils.format_btc(MiningFarm.get_fees_per_second() * 3600.0), MiningFarm.get_ai_timer_multiplier()]

func _refresh() -> void:
	for miner in MiningFarm.MINERS:
		if !_miner_buttons.has(miner.id): continue
		var button: Button = _miner_buttons[miner.id]
		var cost: float = MiningFarm.get_miner_cost(miner.id)
		button.text = "%s x%d  ·  Buy $%s" % [miner.name, MiningFarm.get_owned(miner.id), Utils.format_currency(cost, true)]
		button.disabled = BitcoinWallet.get_fiat_balance() < cost

	_achievements_label.text = "Achievements: %d/%d" % [Achievements.get_unlocked_count(), Achievements.ACHIEVEMENTS.size()]
	var lines: PackedStringArray = []
	for achievement in Achievements.ACHIEVEMENTS:
		var mark: String = "[x]" if Achievements.is_unlocked(achievement.id) else "[ ]"
		lines.append("%s %s: %s" % [mark, achievement.name, achievement.description])
	_achievements_label.tooltip_text = "\n".join(lines)

	_epoch_label.text = "Epoch %d  ·  HODL points %d (+%d%% hashrate, +%d%% fiat)" % [MiningFarm.epoch, MiningFarm.hodl_points, roundi(MiningFarm.hodl_points * MiningFarm.HASHRATE_BONUS_PER_POINT * 100.0), roundi(MiningFarm.hodl_points * MiningFarm.FIAT_DROP_BONUS_PER_POINT * 100.0)]
	var can_reset: bool = MiningFarm.can_start_new_epoch()
	_epoch_button.disabled = !can_reset
	_epoch_button.text = "New Epoch: +%d HODL points" % MiningFarm.get_points_for_new_epoch() if can_reset else "New Epoch: mine every block first"

func _on_buy_miner_pressed(miner_id: String) -> void:
	if MiningFarm.buy_miner(miner_id):
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)

func _on_epoch_button_pressed() -> void:
	_confirm_dialog.dialog_text = "Everything resets: blocks, wallet, upgrades, miners and inflation.\nYou keep %d new HODL points (one per square root of the BTC you hold)." % MiningFarm.get_points_for_new_epoch()
	_confirm_dialog.popup_centered()

func _on_confirm_dialog_confirmed() -> void:
	new_epoch_requested.emit()

func _on_state_changed(_a = null, _b = null) -> void:
	_refresh()
