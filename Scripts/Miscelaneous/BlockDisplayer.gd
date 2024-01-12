class_name BlockDisplayer extends PanelContainer

@onready var block_label: Label = %BlockLabel


func set_label_text(value: String) -> void:
	block_label.text = value
