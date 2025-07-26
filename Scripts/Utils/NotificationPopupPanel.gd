class_name NotificationPopupPanel extends PopupPanel
## Controls the dynamic display of economic event info and other notifications.
##
## This panel is used to show detailed information about economic events
## and other notifications in the game. It can be shown with specific event data
## passed to the `show_economic_event` or `show_custom` methods.

@onready var _title_label: AnimatedLabel = %TitleLabel
@onready var _description_label: AnimatedLabel = %DescriptionLabel
@onready var _impact_value_label: AnimatedLabel = %ImpactValueLabel
@onready var _currency_value_label: AnimatedLabel = %CurrencyValueLabel
@onready var _duration_value_label: AnimatedLabel = %DurationValueLabel
@onready var _close_button: Button = %CloseButton
@onready var _impact_label: AnimatedLabel = %ImpactLabel
@onready var _currency_label: AnimatedLabel = %CurrencyLabel
@onready var _duration_label: AnimatedLabel = %DurationLabel


@onready var _economic_event_passed: Control = %EconomicEventPassed
@onready var _main_container: MarginContainer = %MainContainer

@onready var _non_editable_title_label: AnimatedLabel = %NonEditableTitleLabel
@onready var _event_passed_notification_description: AnimatedLabel = %EventPassedNotificationDescription


func _ready():
	self.size = Vector2i(600, 512)  # Start with initial size
	hide()
	_economic_event_passed.hide()

## Shows the panel with economic event info
func show_economic_event(event):
	_main_container.show()
	_economic_event_passed.hide()

	_title_label.animate_label(0.05)
	_description_label.animate_label_custom_text(event.description, 0.05)
	_impact_value_label.animate_label_custom_text(_calculate_event_impact(event.impact), 0.1)  # Display impact as a percentage

	var currency_suffix: String = _calculate_currency_suffix(event.currency_affected)
	_currency_value_label.animate_label_custom_text(Utils.enum_label(Constants.CurrencyType, event.currency_affected) + currency_suffix, 0.1)

	_duration_value_label.animate_label_custom_text("%d blocks" % event.duration_in_blocks, 0.1)

	_impact_label.animate_label(0.1)
	_currency_label.animate_label(0.1)
	_duration_label.animate_label(0.1)

	await _tween_popup_size()

func _calculate_event_impact(impact: float) -> String:
	var impact_percentage: float = impact * 100.0

	if impact_percentage <= 25.0:
		return "Low (%.1f %%)" % impact_percentage
	elif impact_percentage > 25.0 and impact_percentage <= 49.0:
		return "Medium (%.1f %%)" % impact_percentage
	elif impact_percentage > 49.0 and impact_percentage <= 75.0:
		return "High (%.1f %%)" % impact_percentage
	else:
		return "Dark Souls Level (%.1f %%)" % impact_percentage


func _calculate_currency_suffix(type: Constants.CurrencyType) -> String:
	match type:
		Constants.CurrencyType.FIAT:
			return " ($)"
		Constants.CurrencyType.BITCOIN:
			return " (₿)"
		Constants.CurrencyType.BOTH:
			return " (₿|$)"
		_:
			return ""  # Default case, should not happen


func show_economic_event_passed(_event: EconomicEvent):
	_main_container.hide()
	_economic_event_passed.show()

	_non_editable_title_label.animate_label(0.1)
	_event_passed_notification_description.animate_label_custom_text(
		"Event '%s' has passed. All effects reverted." % _event.name, 0.1
	)

	await _tween_popup_size(Vector2i(600, 512), 0.5)


func _tween_popup_size(target_size: Vector2i = Vector2i(600, 512), duration: float = 0.8):
	# Start from initial size
	self.size = Vector2i(500, 363)
	self.popup_centered()
	var tween = create_tween()
	tween.tween_property(self, "size", target_size, duration).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT)

	await tween.finished

## Shows the panel with custom info
func show_custom(_title: String, info: Dictionary):
	_title_label.text = _title
	if info.has("description"): _description_label.text = str(info["description"])
	if info.has("impact"): _impact_value_label.text = str(info["impact"])
	if info.has("currency"): _currency_value_label.text = str(info["currency"])
	if info.has("duration"): _duration_value_label.text = str(info["duration"])
	_tween_popup_size()

func _on_close_button_pressed() -> void:
	self.hide()
