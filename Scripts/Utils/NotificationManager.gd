extends Control
## NotificationManager: Displays brief UI notifications for various game events.
##
## Autoload this script as "NotificationManager" for global access.

@export var _main_event_bus: MainEventBus

const NOTIF_DURATION: float = 2.0
const START_POSITION: Vector2 = Vector2(40, 40)
@onready var _notification_panel: NotificationPanel = %NotificationPanel
@onready var _notification_popup_panel: NotificationPopupPanel = %NotificationPopupPanel

var _queue: Array = []
var _showing: bool = false

func _ready():
	_main_event_bus.economy_event_picked.connect(_on_economic_event_picked)
	_main_event_bus.economy_event_expired.connect(_notification_popup_panel.show_economic_event_passed)
	BitcoinNetwork.halving_occurred.connect(_on_halving_occurred)
	FED.inflation_applied.connect(_on_inflation_applied)

func _exit_tree() -> void:
	BitcoinNetwork.halving_occurred.disconnect(_on_halving_occurred)
	FED.inflation_applied.disconnect(_on_inflation_applied)

# Handles the economic event picked signal and shows the notification panel.
# [param economic_event]: The economic event that was picked.
# This method updates the notification popup panel with the event details.
func _on_economic_event_picked(economic_event: EconomicEvent) -> void:
	_notification_popup_panel.show_economic_event(economic_event)

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
