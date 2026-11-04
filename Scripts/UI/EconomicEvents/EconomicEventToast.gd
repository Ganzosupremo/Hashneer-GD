class_name EconomicEventToast extends PanelContainer
## Card that slides in under the event badge of the top bar when an economic event starts or ends.
##
## It closes by itself after a few seconds, the countdown pauses while the mouse is over it
## and a click closes it. Cards are queued, so several events never overlap.
## Shown by [NotificationManager], which waits until a hub screen is open.

const SLIDE_TIME: float = 0.35
## Seconds a started event stays on screen.
const START_DURATION: float = 7.0
## Seconds an ended event stays on screen.
const END_DURATION: float = 4.0
## Distance from the top of the screen, below the top bar.
const TOP_MARGIN: float = 72.0
## Distance from the right edge, lines up with the badge in the top bar.
const RIGHT_MARGIN: float = 18.0

@onready var _type_tag: Label = %TypeTag
@onready var _title_label: Label = %TitleLabel
@onready var _blocks_label: Label = %BlocksLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _effects_label: RichTextLabel = %EffectsLabel
@onready var _separator: HSeparator = %Separator
@onready var _time_bar: ProgressBar = %TimeBar

var _queue: Array[Dictionary] = []
var _busy: bool = false
var _counting: bool = false
var _hovered: bool = false
var _time_left: float = 0.0
var _duration: float = 1.0
var _tween: Tween
var _panel_style: StyleBoxFlat
var _tag_style: StyleBoxFlat
var _bar_style: StyleBoxFlat


func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Click to close"
	# Own copies, the border color changes with each event
	_panel_style = (get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	add_theme_stylebox_override("panel", _panel_style)
	_tag_style = (_type_tag.get_theme_stylebox("normal") as StyleBoxFlat).duplicate()
	_type_tag.add_theme_stylebox_override("normal", _tag_style)
	_bar_style = (_time_bar.get_theme_stylebox("fill") as StyleBoxFlat).duplicate()
	_time_bar.add_theme_stylebox_override("fill", _bar_style)
	mouse_entered.connect(func() -> void: _hovered = true)
	mouse_exited.connect(func() -> void: _hovered = false)

## Queues a card for [param event]. [param ended]: the event is over instead of starting.
func enqueue(event: EconomicEvent, ended: bool = false) -> void:
	if event == null:
		return
	_queue.append({"event": event, "ended": ended})
	if not _busy:
		_show_next()

func is_busy() -> bool:
	return _busy

func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		hide()
		return
	_busy = true
	var item: Dictionary = _queue.pop_front()
	_fill(item.event, item.ended)
	_duration = END_DURATION if item.ended else START_DURATION
	_time_left = _duration
	_time_bar.value = 1.0

	show()
	reset_size()
	# Wait a frame so the container has its final height before sliding
	await get_tree().process_frame
	_align_right()
	position.y = -size.y - 8.0
	modulate.a = 0.0
	AudioManager.create_audio(SoundEffectDetails.SoundEffectType.NOTIFICATION_SOUND, AudioManager.DestinationAudioBus.SFX)
	_play_tween(TOP_MARGIN, 1.0, Tween.EASE_OUT)
	await _tween.finished
	_counting = true

func _fill(event: EconomicEvent, ended: bool) -> void:
	var tone: EconomicEvent.Tone = event.get_tone()
	var color: Color = Color(0.55, 0.7, 0.78) if ended else EconomicEvent.tone_color(tone)
	_panel_style.border_color = Color(color, 0.85)
	_tag_style.bg_color = Color(color, 0.16)
	_tag_style.border_color = Color(color, 0.7)
	_type_tag.add_theme_color_override("font_color", color)
	_bar_style.bg_color = Color(color, 0.8)

	if ended:
		_type_tag.text = "EVENT OVER"
		_title_label.text = event.name.to_upper()
		_blocks_label.text = ""
		_description_label.text = "Markets are calm again, prices are back to normal."
		_effects_label.hide()
		_separator.hide()
		return

	_type_tag.text = event.get_type_label()
	_title_label.text = event.name.to_upper()
	var blocks: int = EconomicEventsManager.get_remaining_blocks()
	if blocks <= 0:
		blocks = event.duration_in_blocks
	_blocks_label.text = "%d block%s" % [blocks, "" if blocks == 1 else "s"]
	_description_label.text = event.description
	_effects_label.text = event.get_effects_bbcode()
	_effects_label.visible = not _effects_label.text.is_empty()
	_separator.visible = _effects_label.visible

func _process(delta: float) -> void:
	if not _counting:
		return
	if not _hovered:
		_time_left -= delta
	_time_bar.value = clampf(_time_left / _duration, 0.0, 1.0)
	if _time_left <= 0.0:
		_dismiss()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if _counting:
			_dismiss()

func _dismiss() -> void:
	_counting = false
	_hovered = false
	_play_tween(-size.y - 8.0, 0.0, Tween.EASE_IN)
	await _tween.finished
	_show_next()

func _play_tween(target_y: float, target_alpha: float, ease_type: Tween.EaseType) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(ease_type)
	_tween.tween_property(self, "position:y", target_y, SLIDE_TIME)
	_tween.tween_property(self, "modulate:a", target_alpha, SLIDE_TIME)

func _align_right() -> void:
	position.x = get_parent_area_size().x - size.x - RIGHT_MARGIN
