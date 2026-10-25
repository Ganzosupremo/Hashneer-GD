class_name TesterSection extends VBoxContainer
## A category of the Feature Tester panel: a title and its feature buttons.

@onready var _title_label: Label = %TitleLabel
@onready var _buttons: HFlowContainer = %Buttons

func set_title(title: String) -> void:
	_title_label.text = title

func add_feature_button(button: TesterFeatureButton) -> void:
	_buttons.add_child(button)

func get_feature_buttons() -> Array[Node]:
	return _buttons.get_children()
