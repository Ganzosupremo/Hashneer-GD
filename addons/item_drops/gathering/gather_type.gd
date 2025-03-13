class_name GatherType
extends Resource
## Defines a type of resource being harvested during a gather event
## Can be used to filter out what types of objects are allowed to be harvested by which gatherers

## Name to show in game whenever you want to indicate the gather type
@export var display_name : StringName

## Icon used to indicate the gather type
@export var icon : Texture
