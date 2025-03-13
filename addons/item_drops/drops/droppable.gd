@tool
class_name Droppable
extends Resource
## Represents a item dropped as a instanced scene into the game world

## The path to the drop scene to be instanced when a drop occurs
@export_file("*.tscn") var drop_path : String :
	set(value):
		drop_path = value
		
		# Validate drop path
		if drop_path.is_empty():
			push_warning("There is no drop_path set on resource %s" % [resource_path])
		elif not ResourceLoader.exists(drop_path):
			push_warning("There is no valid resource at path %s" % drop_path)

## Chance of the item scene dropping per roll
@export_range(0.0, 1.0) var odds = 1.0
