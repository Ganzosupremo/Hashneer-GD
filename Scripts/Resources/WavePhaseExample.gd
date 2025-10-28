extends Node2D
## Example script showing how to set up wave phases for a level
## Attach this to your level/game manager node

@onready var wave_spawner: WaveSpawner = $WaveSpawner

func _ready() -> void:
	# Connect to phase change signal for UI updates or effects
	wave_spawner.phase_changed.connect(_on_phase_changed)
	
	# Setup the phases for this level
	setup_wave_phases()

## Example 1: Simple 3-phase progression
func setup_wave_phases() -> void:
	var phases: Array[WavePhase] = []
	
	# Phase 1: Early game - Basic enemies (Waves 1-4)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.BASIC_SQUARE, "count": 12},
		{"enemy_type": Constants.EnemyType.BASIC_TRIANGLE, "count": 6},
	]))
	
	# Phase 2: Mid game - Mixed threats (Waves 5-8)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.BASIC_SQUARE, "count": 8},
		{"enemy_type": Constants.EnemyType.SHOOTER, "count": 5},
		{"enemy_type": Constants.EnemyType.FAST_DART, "count": 4},
		{"enemy_type": Constants.EnemyType.CHARGER, "count": 3},
	]))
	
	# Phase 3: Late game - Challenging enemies (Waves 9+, repeats indefinitely)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.TANK, "count": 4},
		{"enemy_type": Constants.EnemyType.SNIPER, "count": 3},
		{"enemy_type": Constants.EnemyType.EXPLODER, "count": 5},
		{"enemy_type": Constants.EnemyType.HEALER, "count": 2},
		{"enemy_type": Constants.EnemyType.SPINNER, "count": 3},
		{"enemy_type": Constants.EnemyType.TELEPORTER, "count": 2},
	]))
	
	# Apply the phases to the wave spawner
	wave_spawner.set_waves_phases_data(phases)
	wave_spawner.waves_per_phase = 4  # Change phase every 4 waves

## Example 2: 5-phase progression for harder levels
func setup_advanced_wave_phases() -> void:
	var phases: Array[WavePhase] = []
	
	# Phase 1: Tutorial (Waves 1-3)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.BASIC_SQUARE, "count": 10},
	]))
	
	# Phase 2: Introduction (Waves 4-6)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.BASIC_SQUARE, "count": 8},
		{"enemy_type": Constants.EnemyType.SHOOTER, "count": 4},
	]))
	
	# Phase 3: Escalation (Waves 7-9)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.SHOOTER, "count": 5},
		{"enemy_type": Constants.EnemyType.FAST_DART, "count": 4},
		{"enemy_type": Constants.EnemyType.CHARGER, "count": 3},
	]))
	
	# Phase 4: Intense (Waves 10-12)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.TANK, "count": 3},
		{"enemy_type": Constants.EnemyType.SNIPER, "count": 3},
		{"enemy_type": Constants.EnemyType.EXPLODER, "count": 4},
		{"enemy_type": Constants.EnemyType.SPLITTER, "count": 3},
	]))
	
	# Phase 5: Maximum difficulty (Waves 13+)
	phases.append(wave_spawner.create_wave_phase([
		{"enemy_type": Constants.EnemyType.TANK, "count": 4},
		{"enemy_type": Constants.EnemyType.SNIPER, "count": 3},
		{"enemy_type": Constants.EnemyType.EXPLODER, "count": 5},
		{"enemy_type": Constants.EnemyType.HEALER, "count": 2},
		{"enemy_type": Constants.EnemyType.SPINNER, "count": 3},
		{"enemy_type": Constants.EnemyType.TELEPORTER, "count": 3},
		{"enemy_type": Constants.EnemyType.SPLITTER, "count": 2},
	]))
	
	wave_spawner.set_waves_phases_data(phases)
	wave_spawner.waves_per_phase = 3  # Faster progression

## Called when phase changes
func _on_phase_changed(phase_index: int, wave_number: int) -> void:
	print("Phase changed to ", phase_index + 1, " at wave ", wave_number)
	
	# Example: Update UI
	if has_node("UI/PhaseLabel"):
		var phase_names = ["Warm Up", "Getting Serious", "Bring It On!", "Chaos", "Survival"]
		if phase_index < phase_names.size():
			$UI/PhaseLabel.text = "Phase %d: %s" % [phase_index + 1, phase_names[phase_index]]
	
	# Example: Change background music based on phase
	match phase_index:
		0:
			# Light music for phase 1
			pass
		1:
			# Medium intensity for phase 2
			pass
		2:
			# High intensity for final phase
			if has_node("MusicPlayer"):
				# $MusicPlayer.stream = preload("res://Audio/Music/intense_combat.ogg")
				# $MusicPlayer.play()
				pass
	
	# Example: Visual effects
	if wave_spawner.is_last_phase():
		print("WARNING: Final phase reached - prepare for maximum difficulty!")
		# Show warning UI, change screen tint, etc.

## Example: Query wave system state
func update_wave_ui() -> void:
	var info = wave_spawner.get_wave_info()
	
	print("Current Wave: ", info.current_wave)
	print("Current Phase: ", info.current_phase + 1, " / ", info.total_phases)
	print("Waves until next phase: ", info.waves_per_phase - (info.current_wave - 1) % info.waves_per_phase)
	print("Enemies remaining: ", info.alive_enemies, " / ", info.enemies_in_wave)
	
	if wave_spawner.is_last_phase():
		print("On final phase - will continue indefinitely")
