extends ParallaxBackground

@export var scrolling_speed: Vector2 = Vector2(40, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	scroll_offset += scrolling_speed * delta
