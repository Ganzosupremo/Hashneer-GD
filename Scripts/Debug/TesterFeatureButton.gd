class_name TesterFeatureButton extends Button
## Button that runs one [TesterFeature], it shows the on/off state of toggle features.

signal feature_pressed(feature: TesterFeature)

var feature: TesterFeature

func setup(new_feature: TesterFeature) -> void:
	feature = new_feature
	text = feature.label
	tooltip_text = feature.tooltip
	toggle_mode = feature.is_toggle()
	refresh()

## Syncs the pressed state with the feature, the state can change outside the panel.
func refresh() -> void:
	if feature and feature.is_toggle():
		set_pressed_no_signal(feature.is_on())

func _pressed() -> void:
	feature_pressed.emit(feature)
