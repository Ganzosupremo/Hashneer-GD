class_name AnimatedLabel extends Label

## If true sets the visible_ration to 0
@export var start_invisible: bool = true
@export var animate_on_ready: bool = false
@export var anim_speed: float = 0.25
@export_category("Blinking Cursor")
@export var blinking_cursor: bool = false
@export var original_text: String = ""

var _base_text: String = ""
var _cursor_timer: Timer
var _cursor_visible: bool = false

@onready var _animate_text_component: AnimateTextComponent = $AnimateTextComponent

func _ready() -> void:
	_animate_text_component.animation_finished.connect(_on_animation_finished)
	if start_invisible:
		visible_ratio = 0.0
	
	if animate_on_ready:
		animate_label(anim_speed)

func animate_label(speed: float = 0.25) -> void:
	_animate_text_component.animate_text(speed)

func _on_animation_finished() -> void:
	_base_text = text
	if blinking_cursor:
		_start_cursor_blink()

func _start_cursor_blink() -> void:
	_cursor_timer = Timer.new()
	_cursor_timer.one_shot = false
	_cursor_timer.wait_time = 1.0
	add_child(_cursor_timer)
	_cursor_timer.timeout.connect(_toggle_cursor)
	_cursor_timer.start()

func _toggle_cursor() -> void:
	_base_text = original_text
	_cursor_visible = !_cursor_visible
	_base_text += "_" if _cursor_visible else ""
	text = _base_text
