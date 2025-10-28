class_name WaveComposition extends Resource
## Defines the composition of a wave in terms of enemy types and their counts.
##
## Each WaveComposition instance represents a specific enemy type and how many of that type
## should be spawned in a wave.


@export var enemy_type: Constants.EnemyType
@export var count: int