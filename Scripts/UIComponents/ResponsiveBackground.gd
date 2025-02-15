extends Control

@onready var child_container: Control = $ChildContainer

var center: Vector2 = Vector2.ZERO

func _ready() -> void:
	#var children: Array = get_children()
	center = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2)
	child_container.position = center

func _process(delta: float) -> void:
	var offset: Vector2 = center - get_global_mouse_position() * 2.0 * delta
	var t: Tween = GameManager.init_tween()
	t.tween_property(child_container, "position", offset, 1.0).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

func _on_item_rect_changed() -> void:
	if child_container == null: return
	
	center = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y / 2)
	child_container.global_position = center
