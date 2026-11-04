class_name EconomicEventChip extends PanelContainer
## Small badge in the top bar with the active economic event and its blocks left.
##
## The tooltip lists every effect, a click shows the event card again.
## With no event it reads "Markets calm", so players know where events show up.

const CALM_COLOR: Color = Color(0.54, 0.68, 0.75, 1)

@onready var _top_label: Label = %TopLabel
@onready var _name_label: Label = %NameLabel

var _style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	add_theme_stylebox_override("panel", _style)
	EconomicEventsManager.event_changed.connect(refresh)
	refresh()

func _exit_tree() -> void:
	EconomicEventsManager.event_changed.disconnect(refresh)

func refresh() -> void:
	var event: EconomicEvent = EconomicEventsManager.get_current_event()
	if not EconomicEventsManager.is_event_active() or event == null:
		_top_label.text = "MARKETS"
		_name_label.text = "Calm"
		_set_color(CALM_COLOR, 0.25)
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		tooltip_text = "No economic event right now.\nEach mined block can start one (%d%% chance)." % roundi(EconomicEventsManager.chance_per_block * 100.0)
		return

	var blocks: int = EconomicEventsManager.get_remaining_blocks()
	var blocks_text: String = "%d block%s left" % [blocks, "" if blocks == 1 else "s"]
	_top_label.text = "%s · %s" % [event.get_type_label(), blocks_text]
	_name_label.text = event.name
	_set_color(EconomicEvent.tone_color(event.get_tone()), 0.7)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "%s (%s)\n%s\n\n%s\n\nClick for details" % [event.name, blocks_text, event.description, event.get_effects_text()]

func _set_color(color: Color, border_alpha: float) -> void:
	_top_label.add_theme_color_override("font_color", color)
	_name_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1) if border_alpha > 0.5 else CALM_COLOR)
	_style.border_color = Color(color, border_alpha)
	_style.bg_color = Color(color, 0.08 if border_alpha > 0.5 else 0.03)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if EconomicEventsManager.is_event_active():
			accept_event()
			NotificationManager.show_economic_event(EconomicEventsManager.get_current_event())
