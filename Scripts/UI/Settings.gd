class_name SettingsUI extends Control

signal visibility_state_changed(visible: bool)

@onready var resolutions: OptionButton = %Resolutions
@onready var vsync: CheckButton = %Vsync
@onready var fullscreen: CheckBox = %Fullscreen

var v_mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED

func _ready() -> void:
	# Populate resolutions
	var available_resolutions = [
		Vector2(800, 600),
		Vector2(1024, 768),
		Vector2(1280, 720),
		Vector2(1920, 1080),
		Vector2(2560, 1440),
		Vector2(3840, 2160)
	]
	
	for resolution in available_resolutions:
		resolutions.add_item("%dx%d" % [resolution.x, resolution.y])
	
	# Set current resolution
	var current_resolution = DisplayServer.window_get_size()
	for i in range(resolutions.get_item_count()):
		if resolutions.get_item_text(i) == "%dx%d" % [current_resolution.x, current_resolution.y]:
			resolutions.select(i)
			break
	
	# Set V-Sync state
	var mode: DisplayServer.VSyncMode = DisplayServer.window_get_vsync_mode()
	_enable_vsync(mode)
	# Set Fullscreen state
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
	
	# Connect signals
	resolutions.item_selected.connect(_on_resolution_selected)
	vsync.toggled.connect(_on_vsync_toggled)
	fullscreen.toggled.connect(_on_fullscreen_toggled)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_visibility()


func toggle_visibility() -> void:
	if visible:
		hide()
		visibility_state_changed.emit(visible)
	else:
		show()
		visibility_state_changed.emit(visible)

func _enable_vsync(mode: DisplayServer.VSyncMode) -> void:
	match mode:
		DisplayServer.VSYNC_ENABLED:
			vsync.button_pressed = true
		DisplayServer.VSYNC_DISABLED:
			vsync.button_pressed = false

func _on_resolution_selected(index: int) -> void:
	var resolution_text = resolutions.get_item_text(index)
	var resolution = resolution_text.split("x")
	DisplayServer.window_set_size(Vector2i(int(resolution[0]), int(resolution[1])))

func _on_vsync_toggled(button_pressed: bool) -> void:
	if vsync.button_pressed:
		v_mode = DisplayServer.VSYNC_ENABLED
	else:
		v_mode = DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(v_mode)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
