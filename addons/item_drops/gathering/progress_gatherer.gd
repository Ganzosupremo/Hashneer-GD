class_name ProgressGatherer
extends Node
## Manages harvesting resources from a Gatherable node in a game.
## Works by waiting for a progress bar to fill up before actually gathering from the target node

## Emitted when gathering stops.
signal stopped  

## Path to the ActionProgress scene.
@export_file var gather_progress_scene: String  

## Resource that defines the gatherer's abilities
## This could represent the equipped tool or the character itself in a gathering context
@export var gatherer : Gatherer

## The current resource node being gathered.
var target : Gatherable

## Tracks the gathering progress bar.
var action_progress: ProgressBar: 
	set(value):
		# Disconnect from old progress if it exists.
		if action_progress != null:
			action_progress.finished.disconnect(_on_gather_finished)
		
		action_progress = value
		
		# Connect to new progress if it exists.
		if action_progress != null:
			action_progress.finished.connect(_on_gather_finished)

## Starts gathering from a target, returning the progress instance.
func start(gather_target: Gatherable) -> ProgressBar:
	# Clear any existing progress.
	if action_progress != null:
		action_progress.queue_free()
	
	target = gather_target
	action_progress = load(gather_progress_scene).instantiate()
	get_parent().add_child(action_progress)
	
	var gather_time = target.stats.gather_time / gatherer.stats.gather_rate
	action_progress.start(gather_time)
	return action_progress

## Stops the current gathering process, if active.
func stop() -> void:
	if action_progress != null:
		action_progress.queue_free()
	
	target = null
	stopped.emit()

## Handles the completion of a gather cycle.
func _on_gather_finished() -> void:
	if target == null:
		return
	
	var event := GatherEvent.new(target, gatherer, 1)
	target.gather(event)
	
	if not target.gatherable:
		stop()
