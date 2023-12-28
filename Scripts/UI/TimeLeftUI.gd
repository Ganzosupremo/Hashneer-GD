extends Control

@onready var time_left_label: Label = %TimeLeftLabel

func update_label(value: String) -> void:
	time_left_label.text = value + " s"
