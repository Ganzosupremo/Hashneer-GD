class_name ItemDropsBus
extends Resource

## Emitted when an scene is dropped into the game world as a Node2D
signal item_dropped(event : SpawnEvent)

## Emitted when a scene is picked up by another node but before the
## pickup scene is removed from the 2D game world
signal item_picked(event : PickupEvent)

## Emitted when a Gatherable is gathered
signal gathered(event : GatherEvent)
