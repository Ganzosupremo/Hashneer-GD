extends Node2D

@onready var block_core: BlockCore = $BlockCore

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Test_input"):
		block_core.recreate_polygon_shape()
		block_core.queue_redraw()
