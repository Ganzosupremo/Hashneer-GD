extends Control
## NotificationManager: Displays brief UI notifications for various game events.
##
## Autoload this script as "NotificationManager" for global access.

const NOTIF_DURATION: float = 2.0
const START_POSITION: Vector2 = Vector2(40, 40)
const NotificationPanelScene: PackedScene = preload("res://Scenes/UI/NotificationPanel.tscn")

func _ready():
	BitcoinNetwork.halving_occurred.connect(_on_halving_occurred)

func _exit_tree() -> void:
	BitcoinNetwork.halving_occurred.disconnect(_on_halving_occurred)

func _on_halving_occurred(new_subsidy: float) -> void:
	show_notification("Halving! New subsidy: %s BTC" % str(new_subsidy))

## Instance a NotificationPanel scene and configure it.[br]
## [param text]: The notification text to display.
## [param duration]: The duration for which the notification is displayed.
func show_notification(text: String, duration: float = NOTIF_DURATION) -> void:
	var panel: NotificationPanel = NotificationPanelScene.instantiate()
	add_child(panel)
	panel.global_position = START_POSITION
	await panel.tween_panel(text, duration)
		
