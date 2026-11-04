class_name EconomicEvent extends Resource
## A random economic event that changes prices and earnings for a few blocks.
##
## Events live as .tres files in [constant RandomEconomicEventPicker.EVENTS_DIR], adding a file there
## is enough for it to show up in the game. Each effect is a multiplier, [code]1.0[/code] means no change.
## The [RandomEconomicEventPicker] (autoload [code]EconomicEventsManager[/code]) picks them and
## the systems read the active multipliers with [method RandomEconomicEventPicker.get_multiplier].

## Flavor of the event, used for the tag and the color of the notifications.
enum EventType {
	INFLATION, ## Fiat loses value: fiat prices go up.
	DEFLATION, ## Fiat gains value: fiat prices go down.
	MARKET_CRASH, ## Bitcoin price falls.
	MARKET_BOOM, ## Bitcoin price rises.
	TAX_CHANGE, ## Taxes go up or down.
	TECHNOLOGY_ADVANCEMENT, ## Cheaper or better mining hardware.
	NATURAL_DISASTER, ## Supply chains and energy break down.
	NETWORK, ## Something happens on the Bitcoin network itself.
}

## Whether an effect is good or bad for the player, decides its color.
enum Tone { GOOD, BAD, NEUTRAL }

## Effects, each one is the name of a multiplier property below.
const SKILL_COST_FIAT: StringName = &"skill_cost_fiat"
const SKILL_COST_BTC: StringName = &"skill_cost_btc"
const FIAT_DROPS: StringName = &"fiat_drops"
const BTC_PRICE: StringName = &"btc_price"
const MINER_COST: StringName = &"miner_cost"
const MINING_FEES: StringName = &"mining_fees"

## Every effect in display order: label and whether a higher value is good for the player.
const EFFECTS: Dictionary = {
	SKILL_COST_FIAT: {"label": "Fiat skill prices", "higher_is_good": false},
	SKILL_COST_BTC: {"label": "BTC skill prices", "higher_is_good": false},
	FIAT_DROPS: {"label": "Fiat drops", "higher_is_good": true},
	BTC_PRICE: {"label": "BTC exchange price", "higher_is_good": null},
	MINER_COST: {"label": "Miner prices", "higher_is_good": false},
	MINING_FEES: {"label": "Mining fees", "higher_is_good": true},
}

const GOOD_COLOR: Color = Color(0.4, 0.95, 0.5)
const BAD_COLOR: Color = Color(1.0, 0.42, 0.38)
const NEUTRAL_COLOR: Color = Color(1.0, 0.78, 0.3)

## Unique key, saved while the event is active. Defaults to the file name.
@export var id: StringName
## Name shown to the player.
@export var name: String
## One or two sentences of flavor text.
@export_multiline var description: String
@export var event_type: EventType
## How many blocks the event lasts. Blocks are mined by the player and by the AI.
@export_range(1, 20) var duration_in_blocks: int = 2
## Relative chance of being picked against the other events.
@export_range(0.0, 10.0, 0.05) var weight: float = 1.0
## The event can't happen before this many blocks have been mined.
@export var min_blockheight: int = 0

@export_group("Effects (1 = no change)")
## Multiplies the price of skills paid with fiat.
@export_range(0.1, 5.0, 0.05) var skill_cost_fiat: float = 1.0
## Multiplies the price of skills paid with Bitcoin.
@export_range(0.1, 5.0, 0.05) var skill_cost_btc: float = 1.0
## Multiplies the fiat dropped in levels.
@export_range(0.1, 5.0, 0.05) var fiat_drops: float = 1.0
## Multiplies the price of 1 BTC on the exchange.
@export_range(0.1, 5.0, 0.05) var btc_price: float = 1.0
## Multiplies the price of miners in the mining farm.
@export_range(0.1, 5.0, 0.05) var miner_cost: float = 1.0
## Multiplies the fees the mining farm earns.
@export_range(0.1, 5.0, 0.05) var mining_fees: float = 1.0


## The multiplier of [param effect], one of the effect constants. 1.0 for unknown effects.
func get_multiplier(effect: StringName) -> float:
	if not EFFECTS.has(effect):
		return 1.0
	return float(get(effect))

## Effects that change something, in display order, as [code]{effect, text, tone}[/code].
func get_effect_lines() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for effect in EFFECTS:
		var value: float = get_multiplier(effect)
		if is_equal_approx(value, 1.0):
			continue
		lines.append({
			"effect": effect,
			"value": value,
			"text": "%s %s" % [EFFECTS[effect].label, format_change(value)],
			"tone": get_effect_tone(effect, value),
		})
	return lines

## The effects as BBCode, one colored line each.
func get_effects_bbcode() -> String:
	var lines: PackedStringArray = []
	for line in get_effect_lines():
		lines.append("[color=#%s]%s %s[/color]" % [tone_color(line.tone).to_html(false), "▲" if line.value > 1.0 else "▼", line.text])
	return "\n".join(lines)

## The effects as plain text, one per line, for tooltips.
func get_effects_text() -> String:
	var lines: PackedStringArray = []
	for line in get_effect_lines():
		lines.append("- " + line.text)
	return "\n".join(lines)

## GOOD if every effect helps the player, BAD if every effect hurts, NEUTRAL otherwise.
func get_tone() -> Tone:
	var good: int = 0
	var bad: int = 0
	for line in get_effect_lines():
		match line.tone:
			Tone.GOOD: good += 1
			Tone.BAD: bad += 1
	if good > 0 and bad == 0:
		return Tone.GOOD
	if bad > 0 and good == 0:
		return Tone.BAD
	return Tone.NEUTRAL

func get_type_label() -> String:
	return type_label(event_type)


static func get_effect_tone(effect: StringName, value: float) -> Tone:
	var higher_is_good = EFFECTS[effect].higher_is_good if EFFECTS.has(effect) else null
	if higher_is_good == null or is_equal_approx(value, 1.0):
		return Tone.NEUTRAL
	return Tone.GOOD if (value > 1.0) == higher_is_good else Tone.BAD

## "+40%", "-20%", or "x2.5" for big changes.
static func format_change(value: float) -> String:
	if value >= 2.0:
		return "x%s" % str(snappedf(value, 0.1))
	var percent: int = roundi((value - 1.0) * 100.0)
	return ("+%d%%" if percent > 0 else "%d%%") % percent

static func tone_color(tone: Tone) -> Color:
	match tone:
		Tone.GOOD: return GOOD_COLOR
		Tone.BAD: return BAD_COLOR
	return NEUTRAL_COLOR

static func type_label(event_type_value: EventType) -> String:
	match event_type_value:
		EventType.INFLATION: return "INFLATION"
		EventType.DEFLATION: return "DEFLATION"
		EventType.MARKET_CRASH: return "CRASH"
		EventType.MARKET_BOOM: return "BOOM"
		EventType.TAX_CHANGE: return "TAXES"
		EventType.TECHNOLOGY_ADVANCEMENT: return "TECH"
		EventType.NATURAL_DISASTER: return "DISASTER"
		EventType.NETWORK: return "NETWORK"
	return "EVENT"
