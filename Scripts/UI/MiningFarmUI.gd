class_name MiningFarmUI extends PanelContainer
## Skill tree panel for the [MiningFarm]: buy miners, see hashrate and fees, achievements and start a new epoch.
##
## The panel is built in code and added by [SkillTreeManager].

## Emitted when the player confirms starting a new epoch.
signal new_epoch_requested()

const FONT_SIZE: int = 10

var _hashrate_label: Label
var _fees_label: Label
var _epoch_label: Label
var _achievements_label: Label
var _miner_buttons: Dictionary = {}
var _epoch_button: Button
var _confirm_dialog: ConfirmationDialog


func _ready() -> void:
	theme = preload("res://game_main_theme.tres")
	_build()
	BitcoinWallet.money_changed.connect(_on_state_changed)
	MiningFarm.miner_bought.connect(_on_state_changed)
	Achievements.achievement_unlocked.connect(_on_state_changed)
	_refresh()

func _exit_tree() -> void:
	BitcoinWallet.money_changed.disconnect(_on_state_changed)
	MiningFarm.miner_bought.disconnect(_on_state_changed)
	Achievements.achievement_unlocked.disconnect(_on_state_changed)

func _build() -> void:
	var margin: MarginContainer = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	margin.add_child(vbox)

	var title: Label = _label("Mining Farm")
	title.add_theme_font_size_override("font_size", FONT_SIZE + 4)
	vbox.add_child(title)

	_hashrate_label = _label()
	_fees_label = _label()
	vbox.add_child(_hashrate_label)
	vbox.add_child(_fees_label)

	for miner in MiningFarm.MINERS:
		var button: Button = Button.new()
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.tooltip_text = "+%s TH/s" % str(miner.hashrate)
		button.pressed.connect(_on_buy_miner_pressed.bind(miner.id))
		vbox.add_child(button)
		_miner_buttons[miner.id] = button

	vbox.add_child(HSeparator.new())
	_achievements_label = _label()
	_achievements_label.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(_achievements_label)
	_epoch_label = _label()
	vbox.add_child(_epoch_label)

	_epoch_button = Button.new()
	_epoch_button.add_theme_font_size_override("font_size", FONT_SIZE)
	_epoch_button.pressed.connect(_on_epoch_button_pressed)
	vbox.add_child(_epoch_button)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "Start a new epoch?"
	_confirm_dialog.confirmed.connect(func() -> void: new_epoch_requested.emit())
	add_child(_confirm_dialog)

func _label(text: String = "") -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label

func _process(_delta: float) -> void:
	# Fees and the network share change every second, keep the numbers live
	_hashrate_label.text = "Hashrate: %s TH/s (%.1f%% of network)" % [Utils.format_currency(MiningFarm.get_hashrate(), true), MiningFarm.get_network_share() * 100.0]
	_fees_label.text = "Fees: %s BTC/h  ·  AI timer x%.2f" % [Utils.format_btc(MiningFarm.get_fees_per_second() * 3600.0), MiningFarm.get_ai_timer_multiplier()]

func _refresh() -> void:
	for miner in MiningFarm.MINERS:
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

func _on_state_changed(_a = null, _b = null) -> void:
	_refresh()
