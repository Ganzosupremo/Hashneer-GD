class_name SkillDetailPanel extends PanelContainer
## Side panel of the skill tree: details of the selected skill and buy buttons.
##
## The layout lives in [code]Scenes/SkillTreeSystem/SkillDetailPanel.tscn[/code].
## [method show_skill] is connected to [signal SkillTreeView.skill_selected] in the skill tree scene.

const UNAFFORDABLE_COLOR: Color = Color(0.95, 0.4, 0.38, 1.0)
const AFFORDABLE_COLOR: Color = Color(0.4, 0.95, 0.5, 1.0)
const MISSING_REQUIREMENT_COLOR: Color = Color(0.95, 0.55, 0.4, 1.0)

@export var bitcoin_icon: Texture2D
@export var fiat_icon: Texture2D
## The panel never grows above the bottom of this node (the exchange, CurrencyUI).
## Long descriptions scroll instead.
@export var avoid_node: Control
## Screen height the panel never grows above when [member avoid_node] is not set.
@export var top_limit: float = 232.0
const AVOID_GAP: float = 8.0
## The text part never gets shorter than this, even on small screens.
const MIN_INFO_HEIGHT: float = 40.0

@onready var _placeholder: Label = %Placeholder
@onready var _details: Control = %Details
@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _level_label: Label = %LevelLabel
@onready var _modes_label: Label = %ModesLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _effects_label: Label = %EffectsLabel
@onready var _requirements_label: Label = %RequirementsLabel
@onready var _cost_row: Control = %CostRow
@onready var _cost_icon: TextureRect = %CostIcon
@onready var _cost_label: Label = %CostLabel
@onready var _event_cost_label: Label = %EventCostLabel
@onready var _info_scroll: ScrollContainer = %InfoScroll
@onready var _info_box: VBoxContainer = %InfoBox
@onready var _buy_button: Button = %BuyButton
@onready var _buy_max_button: Button = %BuyMaxButton

var _skill: SkillDefinition


func _ready() -> void:
	_buy_button.pressed.connect(_on_buy_pressed)
	_buy_max_button.pressed.connect(_on_buy_max_pressed)

	SkillProgress.skill_changed.connect(_on_skill_changed)
	SkillProgress.progress_reset.connect(refresh)
	SkillProgress.costs_changed.connect(refresh)
	BitcoinWallet.money_changed.connect(_on_money_changed)
	refresh()

func _exit_tree() -> void:
	SkillProgress.skill_changed.disconnect(_on_skill_changed)
	SkillProgress.progress_reset.disconnect(refresh)
	SkillProgress.costs_changed.disconnect(refresh)
	BitcoinWallet.money_changed.disconnect(_on_money_changed)

func show_skill(skill: SkillDefinition) -> void:
	_skill = skill
	refresh()

func refresh() -> void:
	_placeholder.visible = _skill == null
	_details.visible = _skill != null
	if _skill == null:
		return
	_fit_info_height.call_deferred()

	var id: StringName = _skill.id
	var level: int = SkillProgress.get_level(id)
	var maxed: bool = SkillProgress.is_maxed(id)
	var unlocked: bool = SkillProgress.is_unlocked(id)

	_icon.texture = _skill.get_icon(maxed)
	_name_label.text = _skill.display_name
	_level_label.text = "Maxed" if maxed else "Level %d/%d" % [level, _skill.max_level]
	_modes_label.text = "%s  ·  %s" % [_skill.branch, " + ".join(_skill.get_mode_names())]
	_description_label.text = _skill.description
	_description_label.visible = _skill.description != ""
	_effects_label.text = _build_effects_text(level, maxed)

	_requirements_label.visible = not unlocked
	if not unlocked:
		var names: PackedStringArray = []
		for requirement in _skill.requirements:
			if requirement:
				names.append(str(requirement))
		_requirements_label.text = "Requires " + (" and " if _skill.requires_all else " or ").join(names)
		_requirements_label.add_theme_color_override("font_color", MISSING_REQUIREMENT_COLOR)

	_cost_row.visible = not maxed
	_event_cost_label.visible = false
	_buy_button.visible = not maxed
	_buy_max_button.visible = not maxed and _skill.max_level > 1
	if maxed:
		return

	var currency: Constants.CurrencyType = SkillProgress.current_currency
	var cost: float = SkillProgress.get_cost(id, currency)
	_cost_icon.texture = bitcoin_icon if currency == Constants.CurrencyType.BITCOIN else fiat_icon
	_cost_label.text = Utils.format_btc(cost) if currency == Constants.CurrencyType.BITCOIN else Utils.format_currency(cost, true)
	_cost_label.add_theme_color_override("font_color", AFFORDABLE_COLOR if SkillProgress.can_afford(id, currency) else UNAFFORDABLE_COLOR)
	_show_event_cost(id, currency)
	var can_buy: bool = SkillProgress.can_purchase(id, currency)
	_buy_button.disabled = not can_buy
	_buy_max_button.disabled = not can_buy

## Old price struck through and the change, while an economic event moves this currency's prices.
func _show_event_cost(id: StringName, currency: Constants.CurrencyType) -> void:
	var multiplier: float = SkillProgress.get_event_cost_multiplier(currency)
	var event: EconomicEvent = EconomicEventsManager.get_current_event()
	if is_equal_approx(multiplier, 1.0) or event == null:
		return
	var old_cost: float = SkillProgress.get_cost_without_event(id, currency)
	var old_text: String = Utils.format_btc(old_cost) if currency == Constants.CurrencyType.BITCOIN else Utils.format_currency(old_cost, true)
	var effect: StringName = EconomicEvent.SKILL_COST_BTC if currency == Constants.CurrencyType.BITCOIN else EconomicEvent.SKILL_COST_FIAT
	_event_cost_label.add_theme_color_override("font_color", EconomicEvent.tone_color(EconomicEvent.get_effect_tone(effect, multiplier)))
	_event_cost_label.text = "(was %s, %s)" % [old_text, EconomicEvent.format_change(multiplier)]
	_event_cost_label.tooltip_text = "%s changes this price for %d more blocks" % [event.name, EconomicEventsManager.get_remaining_blocks()]
	_event_cost_label.visible = true

## The panel grows upward from the bottom of the screen. Caps the text part so the top
## stays below [member avoid_node], the rest scrolls.
func _fit_info_height() -> void:
	if not is_inside_tree() or not _details.visible:
		return
	var content: float = _info_box.get_combined_minimum_size().y
	var others: float = get_combined_minimum_size().y - _info_scroll.get_combined_minimum_size().y
	var limit: float = top_limit
	if is_instance_valid(avoid_node) and avoid_node.is_visible_in_tree():
		limit = avoid_node.get_global_rect().end.y + AVOID_GAP
	var allowed: float = get_global_rect().end.y - limit - others
	_info_scroll.custom_minimum_size.y = minf(content, maxf(allowed, MIN_INFO_HEIGHT))

## One line per effect: what it gives now and with the next level.
func _build_effects_text(level: int, maxed: bool) -> String:
	var lines: PackedStringArray = []
	for effect in _skill.effects:
		if effect == null:
			continue
		if effect.is_level_independent():
			lines.append(effect.describe(maxi(level, 1)))
		elif level == 0:
			lines.append("Next: " + effect.describe(1))
		elif maxed:
			lines.append(effect.describe(level))
		else:
			lines.append("%s  ->  %s" % [effect.describe(level), effect.describe(level + 1)])
	return "\n".join(lines)

func _on_buy_pressed() -> void:
	if _skill and SkillProgress.purchase(_skill.id):
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)

func _on_buy_max_pressed() -> void:
	if _skill and SkillProgress.purchase_max(_skill.id) > 0:
		AudioManager.create_audio(SoundEffectDetails.SoundEffectType.UI_BUTTON_CLICK, AudioManager.DestinationAudioBus.SFX)

func _on_skill_changed(_skill_id: StringName, _level: int) -> void:
	refresh()

func _on_money_changed(_amount: float, _currency: Constants.CurrencyType) -> void:
	refresh()
