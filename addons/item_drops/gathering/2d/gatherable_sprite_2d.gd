class_name GatherableSprite2D
extends Sprite2D
## Sprite that automatically updates visually when the gatherable node becomes depleted or refilled to at least 1 gatherable item.

## The gatherable component to react to when it is depleted or refilled
@export var gatherable : Gatherable :
	set(value):
		if gatherable != null:
			gatherable.depleted.disconnect(_on_gatherable_depleted)
			gatherable.refilled.disconnect(_on_gatherable_refilled)
			
		gatherable = value
		
		if gatherable != null:
			gatherable.depleted.connect(_on_gatherable_depleted)
			gatherable.refilled.connect(_on_gatherable_refilled)
			
@export var gatherable_texture : Texture
@export var depleted_texture : Texture

## Set the depleted texture when the gatherable turns depleted
func _on_gatherable_depleted():
	texture = depleted_texture

## Set the gatherable texture when the gatherable turns refilled
func _on_gatherable_refilled():
	texture = gatherable_texture
