class_name DropsGenerator
extends Object
## Uses odds to generate which items from a table should
## be created in the game world

## Where the drops are being generated from. Defines scenes to spawn and odds
var drops_table : DropsTable

## Multiplier times the base odds to modify how often items drop from the table
var odds_multiplier : float

func _init(p_drops_table : DropsTable, p_odds_multiplier : float) -> void:
	drops_table = p_drops_table
	odds_multiplier = p_odds_multiplier

## Randomly generates drops from the drop table a single time
func generate_drops() -> Array[Droppable]:
	if not drops_table.has_possible_drops():
		push_warning("Drop table %s set up with no drops that are possible. Returning no drops." % drops_table)
		return []
	
	# Combined odds single drop
	if drops_table.combined_odds:
		return [_find_combined_drop()]
	
	# Roll for each possible drop individually
	var drops : Array[Droppable] = roll_drops()
	
	## Generates drops until the guaranteed number has been matched
	
	while drops.size() < drops_table.guaranteed_drops:
		var extra_generation : Array[Droppable] = roll_drops()
		drops.append_array(extra_generation)
		
	return drops
	
## Rolls on the table and adds new drops, if any, to the drops array
func roll_drops() -> Array[Droppable]:
	var new_drops : Array[Droppable] = []
		
	for possible_drop in drops_table.possible_drops:
		var gen_result : Droppable = _single_drops_generation(possible_drop)
		
		if gen_result != null:
			new_drops.append(gen_result)
	
	return new_drops
	
## Rolls for generation on a single item to have a chance of dropping
func _single_drops_generation(droppable : Droppable) -> Droppable:
	# Return null immediately if drop has no odds
	if droppable.odds <= 0.0:
		return null
		
	var random_val = randf_range(0.0, 1.0)
	
	## If random number is within the drop odds multiplied by odds_multiplier, 
	## return the droppable indicating a successful drop choice
	if random_val <= droppable.odds * odds_multiplier:
		return droppable
		
	# No drop
	return null
		
## Combine all odds from the drops list (ignoring 0 odds) and then pick one by generating a number from 0 to the combined odds float
func _find_combined_drop() -> Droppable:
	var odds_start = 0.0
	var odds_end = 0.0
	var max_range = get_total_odds()
	var drop_random = randf_range(0.0, max_range)
	
	# Find the drop
	for pos_drop in drops_table.possible_drops:
		# Skip drops with 0 odds
		if pos_drop.odds <= 0.0:
			continue
			
		odds_end += pos_drop.odds
		
		# Is the generated number inside of the odds for this item?
		if drop_random >= odds_start && drop_random <= odds_end:
			return pos_drop # Return the selected drop
		
		odds_start += pos_drop.odds
	
	# Return null if no valid drop found (all odds were 0 or random number exceeds total)
	return null
	
## Gets the cumulative odds adding every possible_drop odds together 
func get_total_odds() -> float:
	var total_odds : float = 0
		
	for pos_drop in drops_table.possible_drops:
		total_odds += pos_drop.odds
		
	return total_odds
