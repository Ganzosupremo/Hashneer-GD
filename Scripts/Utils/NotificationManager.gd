extends Control
## NotificationManager: Displays brief UI notifications for various game events.
##
## Autoload this script as "NotificationManager" for global access.

@export var _main_event_bus: MainEventBus

const NOTIF_DURATION: float = 2.0
const START_POSITION: Vector2 = Vector2(40, 40)
@onready var _notification_panel: NotificationPanel = %NotificationPanel
@onready var _notification_popup_panel: NotificationPopupPanel = %NotificationPopupPanel

func _ready():
	_main_event_bus.economy_event_picked.connect(_on_economic_event_picked)
	_main_event_bus.economy_event_expired.connect(_notification_popup_panel.show_economic_event_passed)
	BitcoinNetwork.halving_occurred.connect(_on_halving_occurred)

func _exit_tree() -> void:
	BitcoinNetwork.halving_occurred.disconnect(_on_halving_occurred)

# Handles the economic event picked signal and shows the notification panel.
# [param economic_event]: The economic event that was picked.
# This method updates the notification popup panel with the event details.
func _on_economic_event_picked(economic_event: EconomicEvent) -> void:
	_notification_popup_panel.show_economic_event(economic_event)

# Handles the halving event and shows a notification with the new subsidy.
# [param new_subsidy]: The new subsidy amount after the halving.
# This method updates the notification panel with the new subsidy information.
func _on_halving_occurred(new_subsidy: float) -> void:
	show_notification("Halving! New subsidy: %s BTC" % str(new_subsidy))

## Makes the NotificationPanel visible and configures it.[br]
## [param text]: The notification text to display.
## [param duration]: The duration for which the notification is displayed.
func show_notification(text: String, duration: float = NOTIF_DURATION) -> void:
	_notification_panel.global_position = START_POSITION
	await _notification_panel.tween_panel(text, duration)
