class_name ItemDropsBus
extends Resource

signal item_spawned(event : SpawnEvent)

## Emitted when an scene is dropped into the game world as a Node2D
signal item_dropped(event : SpawnEvent)

## Emitted when a scene is picked up by another node but before the
## pickup scene is removed from the 2D game world
signal item_picked(event : PickupEvent)

## Emitted when a Gatherable is gathered
signal gathered(event : GatherEvent)


func emit_item_spawned(event : SpawnEvent) -> void:
    item_spawned.emit(event)
    # DebugLogger.info("Signal emitted: item_spawned. From {0} spawning {1}".format([event.spawner, event.spawned]), "Item Drop Bus")