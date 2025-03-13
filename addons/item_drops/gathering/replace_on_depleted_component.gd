class_name ReplaceOnDepletedComponent
extends ItemDropsNode
## Replaces one node with a new scene when the gatherable_component's
## depleted signal triggers. You can also leave replacement
## scene blank if you want to simply destroy the target node
## If the replacement and target scenes have a position, the
## new node will take the old one's global position

## Emitted when the old scene is replaced with the new scene before the old_scene is removed
signal replaced(new_scene : Node, old_node : Node)

## Path to the file scene that replaces the old_node
@export_file var replacement_scene

## The node that will be replaced
@export var target_node : Node

## The gatherable component for replacing the old node on depletion
@export var gatherable_component : Gatherable

func _ready():
	gatherable_component.depleted.connect(_on_depleted)

func _on_depleted():
	if(replacement_scene):
		var new_scene = load(replacement_scene).instantiate()
		target_node.get_parent().add_child(new_scene)
		
		if(target_node is Node2D && new_scene is Node2D):
			new_scene.position = target_node.position
		elif(target_node is Node3D && new_scene is Node3D):
			new_scene.position = target_node.position
		
		call_deferred("emit_signal", "replaced", new_scene, target_node)
	
	target_node.call_deferred("queue_free")
