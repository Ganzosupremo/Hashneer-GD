class_name InventoryAccessSettings
extends Resource
## Settings that define how items are added or removed to a system agnostic inventory
## Recommended to save this resource and shared across the project if every
## game object uses the same inventory for items management

## Function to call to get the contents of the inventory
@export var method_get_contents : StringName

## What to call to remove an item (or stack) from the inventory
## [br][br]
## Parameter is one 'item' or 'stack'. Whatever is stored in sequence in the inventory.
@export var method_remove : StringName

## Name of the property on the targeted node that points to the actual inventory object (Resource or otherwise). [br][br]
## Leave blank if the target node itself is the inventory.
@export var prop_inventory : StringName

## The method to try on the inventory to add the picked up items to the inventory
## Parameter should be the Item type, and the count : int to be added
@export var method_add : StringName

## List of properties needed to access the scene path for each invenory contents in order
## to access the path to the in game representation of the item for spawning
@export var path_to_scene_path : Array[StringName]
