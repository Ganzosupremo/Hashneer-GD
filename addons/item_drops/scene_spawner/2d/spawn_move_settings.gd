class_name SpawnMoveSettings
extends Resource
## Settings that define how fast and for how long to move a spawned object with a MoveOnSpawn component
## attached

## The curve that defines how far the object should move over the duration time period
@export var distance_time_curve : Curve

## The duration for how long the move lasts
@export var move_duration : float = 0.15
