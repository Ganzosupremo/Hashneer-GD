extends Control
## NotificationManager: Displays brief UI notifications for various game events.
##
## Autoload this script as "NotificationManager" for global access.

@export var _main_event_bus: MainEventBus

const NOTIF_DURATION: float = 2.0
const START_POSITION: Vector2 = Vector2(40, 40)
@onready var _notification_panel: NotificationPanel = %NotificationPanel
@onready var _event_toast: EconomicEventToast = %EconomicEventToast

var _queue: Array = []
var _showing: bool = false
## Economic event cards waiting for a hub screen, as [code][event, ended][/code].
var _pending_events: Array = []

func _ready():
	BitcoinNetwork.halving_occurred.connect(_on_halving_occurred)
	FED.inflation_applied.connect(_on_inflation_applied)
	EconomicEventsManager.event_started.connect(_on_economic_event_started)
	EconomicEventsManager.event_ended.connect(_on_economic_event_ended)
	SceneManager.scene_switched.connect(_flush_economic_events)

func _exit_tree() -> void:
	BitcoinNetwork.halving_occurred.disconnect(_on_halving_occurred)
	FED.inflation_applied.disconnect(_on_inflation_applied)
	EconomicEventsManager.event_started.disconnect(_on_economic_event_started)
	EconomicEventsManager.event_ended.disconnect(_on_economic_event_ended)
	SceneManager.scene_switched.disconnect(_flush_economic_events)

#region Economic events

## Shows the card of [param event] now, e.g. when the top bar chip is clicked.
func show_economic_event(event: EconomicEvent) -> void:
	if _event_toast.is_busy(): return
	_event_toast.enqueue(event)

func _on_economic_event_started(event: EconomicEvent) -> void:
	_queue_economic_event(event, false)

func _on_economic_event_ended(event: EconomicEvent) -> void:
	_queue_economic_event(event, true)

# Blocks are mostly found at the end of a level, the card waits for the hub so it isn't missed
func _queue_economic_event(event: EconomicEvent, ended: bool) -> void:
	# An event that started and ended while away only needs its end card
	if ended:
		_pending_events = _pending_events.filter(func(item: Array) -> bool: return item[0] != event)
	_pending_events.append([event, ended])
	_flush_economic_events()

func _flush_economic_events() -> void:
	if _pending_events.is_empty(): return
	if SceneManager.is_switching or not SceneManager.is_hub_scene(SceneManager.get_current_scene_enum()): return
	for item in _pending_events:
		_event_toast.enqueue(item[0], item[1])
	_pending_events.clear()

#endregion

# Handles the halving event and shows a notification with the new subsidy.
# [param new_subsidy]: The new subsidy amount after the halving.
# This method updates the notification panel with the new subsidy information.
func _on_halving_occurred(new_subsidy: float) -> void:
	show_notification("Halving! New subsidy: %s BTC. Bitcoin prices drop %d%%" % [Utils.format_btc(new_subsidy), roundi(BitcoinNetwork.deflation_rate * 100.0)], NOTIF_DURATION * 2.0)

func _on_inflation_applied(rate: float, total: float) -> void:
	show_notification("The FED printed money: +%d%% inflation (prices x%.2f)" % [roundi(rate * 100.0), total])

## Makes the NotificationPanel visible and configures it.[br]
## [param text]: The notification text to display.
## [param duration]: The duration for which the notification is displayed.
func show_notification(text: String, duration: float = NOTIF_DURATION) -> void:
	# Several events can fire on the same block, show them one after another
	_queue.append([text, duration])
	if _showing: return
	_showing = true
	while !_queue.is_empty():
		var next: Array = _queue.pop_front()
		_notification_panel.global_position = START_POSITION
		await _notification_panel.tween_panel(next[0], next[1])
	_showing = false
