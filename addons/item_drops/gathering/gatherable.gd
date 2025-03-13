class_name Gatherable
extends ItemDropsNode
## Gives the scene the ability to have items gathered from it until
## the Gatherable is depleted

## Emit when objects are successfully gathered from the node
signal gathered(event : GatherEvent)

## Emit for each gather node is dropped into the game world
signal dropped(dropped_node : Node)

## Emit when the remaining count of resources left on this node changes
signal remaining_changed(remaining : int)

## Emit when the node toggles whether it is enabled or disabled for gathering
signal enabled_changed(value : bool)

## Emit when the node is gatherable or not
signal gatherable_changed(value : bool)

## Emitted when the count remaining drops to 0 or below from any positive previous number
signal depleted()

## Emitted when the count remaining becomes any positive number when the previous was 0 or less 
signal refilled()

## The signal bus that item drops is communicated on
@export var item_drops_bus : ItemDropsBus

## Stats for this gatherable resource
## Set stats become unique
@export var stats : GatherableStats :
	set(value):
		if stats != null:
			stats.remaining_changed.disconnect(_on_remaining_changed)
		
		if value == null:
			stats = null
		else:
			stats = value.duplicate()
			
		if stats != null:
			stats.remaining_changed.connect(_on_remaining_changed)

## The scene to instance into the game world for each amount harvested
## from the component node
@export var drops_table : DropsTable

## Spawns the dropped items into the game world
@export var drop_spawner : Node

## The type of gather node this represents
@export var type : GatherType

## Whether gathering is enabled on the node. Still requires there to be
## remaining amount to harvest items
@export var enabled : bool = true :
	set(value):
		if enabled == value:
			return
			
		enabled = value
		enabled_changed.emit(enabled)

## Whether the object can currently be gathered from or not
var gatherable : bool = true :
	set(value):
		if gatherable == value:
			return
		
		gatherable = value
		gatherable_changed.emit(gatherable)

## Updates the gatherable bool to whether the node can be gathered or not
func update_if_gatherable() -> bool:
	var new_value = stats.remaining > 0 && enabled
	gatherable = new_value
	return gatherable
	
func _ready():
	enabled_changed.connect(_on_enabled_changed)

## Takes resources from the nodes a number of times generating
## drops for each time
##
## Returns true if at least one gather occured
func gather(p_event : GatherEvent) -> int:
	var count_spawned : int
	
	if update_if_gatherable():
		var actual_gathers : int = min(1, stats.remaining)
		
		if actual_gathers > 0:
			var generator = DropsGenerator.new(drops_table, p_event.gatherer.drop_rate_multiplier)
			
			for time in range(0, actual_gathers, 1):
				var selected : Array[Droppable] = generator.generate_drops()
				stats.remaining -= 1
				
				for droppable in selected:
					# Load the scene to drop
					var scene : PackedScene = load(droppable.drop_path)
					
					if scene == null:
						push_warning("No scene loaded from path [%s] so skipping spawning of the Droppable" % droppable.drop_path)
						continue
					
					var spawned : Node = drop_spawner.spawn(scene)
					p_event.gathered.append(spawned)
					count_spawned += 1
					
					# Default scene location is the gatherable component. But this can
					# easily be changed in response to the signal
					dropped.emit(spawned)
					var spawn_event = SpawnEvent.new(drop_spawner, spawned)
					item_drops_bus.item_dropped.emit(spawn_event)
			
			gathered.emit(p_event)
			item_drops_bus.gathered.emit(p_event)
			
	return count_spawned
	
## Add new gathers to the node
func add(amount : int):
	stats.remaining += amount

## Update whether the node is gatherable whenever the enabled status changes
func _on_enabled_changed(_p_value : bool):
	update_if_gatherable()

func _on_remaining_changed(p_remaining : int, p_change : int):
	if p_remaining <= 0 && p_change < 0:
		depleted.emit()
	
	if p_remaining > 0 && abs(p_change) >= p_remaining:
		refilled.emit()
			
	update_if_gatherable()
