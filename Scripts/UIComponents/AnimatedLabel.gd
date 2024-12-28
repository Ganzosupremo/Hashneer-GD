class_name AnimatedLabel extends Label

## If true sets the visible_ration to 0
@export var start_invisible: bool = true

@onready var _animate_text_component: AnimateTextComponent = $AnimateTextComponent

func _ready() -> void:
	if start_invisible:
		visible_ratio = 0.0

func animate_label(speed: float = 0.25) -> void:
	_animate_text_component.animate_text(speed)
