class_name NotificationPopupPanel extends PanelContainer
## Displays economic event alerts and market-stabilized notifications.

@onready var _title_label: AnimatedLabel = %TitleLabel
@onready var _description_label: AnimatedLabel = %DescriptionLabel
@onready var _impact_value_label: AnimatedLabel = %ImpactValueLabel
@onready var _currency_value_label: AnimatedLabel = %CurrencyValueLabel
@onready var _duration_value_label: AnimatedLabel = %DurationValueLabel

@onready var _impact_label: AnimatedLabel = %ImpactLabel
@onready var _currency_label: AnimatedLabel = %CurrencyLabel
@onready var _duration_label: AnimatedLabel = %DurationLabel

@onready var _economic_event_passed: Control = %EconomicEventPassed
@onready var _main_container: MarginContainer = %MainContainer
@onready var _non_editable_title_label: AnimatedLabel = %NonEditableTitleLabel
@onready var _event_passed_notification_description: AnimatedLabel = %EventPassedNotificationDescription


func _ready() -> void:
	hide()
	_main_container.hide()
	_economic_event_passed.hide()


func show_economic_event(event: EconomicEvent) -> void:
	DebugLogger.info("Showing economic event popup")
	_economic_event_passed.hide()
	_main_container.show()
	show()
	await _tween_modulate()

	_title_label.animate_label_custom_text("EVENT // %s" % event.name.to_upper(), 0.04)
	_description_label.animate_label_custom_text(event.description, 0.035)
	_impact_value_label.animate_label_custom_text(_calculate_event_impact(event.impact), 0.07)

	var currency_suffix: String = _calculate_currency_suffix(event.currency_affected)
	_currency_value_label.animate_label_custom_text(
		Utils.enum_label(Constants.CurrencyType, event.currency_affected).to_upper() + currency_suffix,
		0.07
	)
	_duration_value_label.animate_label_custom_text("%d BLOCKS" % event.duration_in_blocks, 0.07)

	_impact_label.animate_label(0.07)
	_currency_label.animate_label(0.07)
	_duration_label.animate_label(0.07)


func _calculate_event_impact(impact: float) -> String:
	var impact_percentage: float = impact * 100.0
	if impact_percentage <= 25.0:
		return "LOW // %.1f%%" % impact_percentage
	elif impact_percentage <= 49.0:
		return "MEDIUM // %.1f%%" % impact_percentage
	elif impact_percentage <= 75.0:
		return "HIGH // %.1f%%" % impact_percentage
	return "EXTREME // %.1f%%" % impact_percentage


func _calculate_currency_suffix(type: Constants.CurrencyType) -> String:
	match type:
		Constants.CurrencyType.FIAT:
			return " (USD)"
		Constants.CurrencyType.BITCOIN:
			return " (BTC)"
		Constants.CurrencyType.BOTH:
			return " (BTC + USD)"
		_:
			return ""


func show_economic_event_passed(event: EconomicEvent) -> void:
	_main_container.hide()
	_economic_event_passed.show()
	show()
	await _tween_modulate()

	_non_editable_title_label.animate_label_custom_text("EVENT CONCLUDED", 0.06)
	_event_passed_notification_description.animate_label_custom_text(
		"Market conditions have stabilized. The economic event '%s' has concluded and its effects have dissipated from the market." % event.name,
		0.045
	)


func _tween_modulate(target_modulate: float = 1.0, duration: float = 0.45) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", target_modulate, duration).from_current().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


func show_custom(title: String, info: Dictionary) -> void:
	_economic_event_passed.hide()
	_main_container.show()
	show()
	_title_label.text = title
	if info.has("description"):
		_description_label.text = str(info["description"])
	if info.has("impact"):
		_impact_value_label.text = str(info["impact"])
	if info.has("currency"):
		_currency_value_label.text = str(info["currency"])
	if info.has("duration"):
		_duration_value_label.text = str(info["duration"])
	_tween_modulate()


func _on_close_button_pressed() -> void:
	await _tween_modulate(0.0, 0.3)
	_main_container.hide()
	_economic_event_passed.hide()
	hide()
