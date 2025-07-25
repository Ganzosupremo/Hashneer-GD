class_name AnimatedLabel extends Label
## This class extends the Label node to provide animated text functionality.
##
## It uses the AnimateTextComponent to animate the text with a typing effect.
## It can also handle a blinking cursor effect if enabled.

## If true sets the visible_ration to 0
@export var start_invisible: bool = true
## If true, the label will animate its text on ready.
@export var animate_on_ready: bool = false
## The speed of the animation in seconds per character.
@export var anim_speed: float = 0.25
@export_category("Blinking Cursor")
## If true, a blinking cursor will be added at the end of the text.
@export var blinking_cursor: bool = false
## The original text to animate.
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

## Sets the text of the label and starts the animation.[br]
## [param _text]: The text to set for the label[br]
## [param speed]: The speed of the animation, default is 0.25 seconds per character[br]
## This method will set the text of the label and start the animation to reveal it character by character.
## If `blinking_cursor` is true, it will also start a blinking cursor at the end of the text.
func animate_label_custom_text(_text: String, speed: float = 0.25) -> void:
	_base_text = _text
	self.text = _base_text
	_animate_text_component.animate_text(speed)

## Starts the animation of the label text.[br]
## [param speed]: The speed of the animation, default is 0.25 seconds per character[br]
## This method will animate the label text by revealing it character by character.
## If [member blinking_cursor] is true, it will also start a blinking cursor at the end of the text.
## The [member original_text] will be used as the base text for the animation.
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
