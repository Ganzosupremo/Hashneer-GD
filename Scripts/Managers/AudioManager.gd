extends Node2D

signal music_clip_changed(music: MusicDetails, time_to_fade: float)

@export var main_game_mixer: AudioBusLayout
## Stores all possible SoundEffects that can be played.
@export var sound_effects: Array[SoundEffectDetails]

@export_range(0.0, 1.0, 0.1) var music_volume: float = .5:
	get:
		return _music_volume
	set(value):
		_music_volume = value
@export_range(0.0, 1.0, 0.1) var master_volume: float = .5:
	get:
		return _master_volume
	set(value):
		_master_volume = value
@export_range(0.0, 1.0, 0.1) var sfx_volume: float = .5:
	get:
		return _sfx_volume
	set(value):
		_sfx_volume = value
@export_range(0.0, 1.0, 0.1) var player_sfx_volume: float = .5:
	get:
		return _player_sfx_volume
	set(value):
		_player_sfx_volume = value
@export_range(0.0, 1.0, 0.1) var weapons_volume: float = .5:
	get:
		return _weapons_volume
	set(value):
		_weapons_volume = value


var _music_volume: float = 0.5
var _sfx_volume: float = 0.5
var _player_sfx_volume: float = 0.5
var _weapons_volume: float = 0.5
var _master_volume: float = 0.5

var current_music_clip: AudioStream
var is_music_clip1_playing: bool = true
var delta_time: float = 0.0
var sound_effect_dict: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var first_audio_stream: AudioStreamPlayer = $FirstAudioStream
@onready var second_audio_stream: AudioStreamPlayer = $SecondAudioStream

@onready var music_bus_index: int = AudioServer.get_bus_index("Music")
@onready var sfx_bus_index: int = AudioServer.get_bus_index("SFX")
@onready var player_sfx_bus_index: int = AudioServer.get_bus_index("Player SFX")
@onready var weapons_bus_index: int = AudioServer.get_bus_index("Weapons")
@onready var master_bus_index: int = AudioServer.get_bus_index("Master") 

func _ready() -> void:
	_rng.randomize()
	for sound_effect in sound_effects:
		sound_effect_dict[SoundEffectDetails.enum_to_string(sound_effect.sound_type)] = sound_effect
	music_clip_changed.connect(_on_music_clip_changed)
	set_music_volume(music_volume)

func _process(delta: float) -> void:
	delta_time = delta

func _on_music_clip_changed(clip: MusicDetails, time_to_fade: float) -> void:
	if clip == null:
		return
	
	current_music_clip = clip.music_clip
	is_music_clip1_playing = !is_music_clip1_playing
	
	var to_play: AudioStream = clip.music_clip if !clip.has_playlist else clip.playlist
	await fade_music(to_play, clip.volume_linear, time_to_fade)

## Creates a sound effect at a specific location if the limit has not been reached. 
## Pass [param location] for the global position of the audio effect, and [param type] for the SoundEffectDetails to be queued.
func create_2d_audio_at_location(location: Vector2, type: SoundEffectDetails.SoundEffectType, destination_audio_bus: SoundEffectDetails.DestinationAudioBus = SoundEffectDetails.DestinationAudioBus.MASTER) -> void:
	if sound_effect_dict.has(SoundEffectDetails.enum_to_string(type)):
		var sound_effect: SoundEffectDetails = sound_effect_dict[SoundEffectDetails.enum_to_string(type)]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_2D_audio: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			add_child(new_2D_audio)
			# Set the audio bus to the correct one
			new_2D_audio.bus = SoundEffectDetails.destination_audio_bus_to_string(destination_audio_bus)
			new_2D_audio.position = location
			new_2D_audio.stream = sound_effect.audio_stream
			new_2D_audio.volume_db = sound_effect.sound_volume
			new_2D_audio.pitch_scale = sound_effect.sound_pitch
			new_2D_audio.pitch_scale += _rng.randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness)
			new_2D_audio.finished.connect(sound_effect.on_audio_finished)
			new_2D_audio.finished.connect(new_2D_audio.queue_free)
			new_2D_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", SoundEffectDetails.enum_to_string(type))

var persistence_audio_player: AudioStreamPlayer2D
## Creates a sound effect at a specific location if the limit has not been reached.
## Pass [param location] for the global position of the audio effect, and [param type] for the SoundEffectDetails to be queued.
## This function will create a persistent audio player that will play the sound effect at the location.
## This is useful for sound effects that need to be played at a specific location, such as footsteps or gunfire.
## The audio player won't be destroyed when the sound effect is finished playing.
func create_2d_audio_at_location_with_persistent_player(location: Vector2, type: SoundEffectDetails.SoundEffectType, destination_audio_bus: SoundEffectDetails.DestinationAudioBus = SoundEffectDetails.DestinationAudioBus.MASTER):
	if sound_effect_dict.has(SoundEffectDetails.enum_to_string(type)):
		var sound_effect: SoundEffectDetails = sound_effect_dict[SoundEffectDetails.enum_to_string(type)]
		
		if !sound_effect.has_open_limit(): return
		
		sound_effect.change_audio_count(1)
		if persistence_audio_player == null:
			persistence_audio_player = AudioStreamPlayer2D.new()
			add_child(persistence_audio_player)
		persistence_audio_player.bus = SoundEffectDetails.destination_audio_bus_to_string(destination_audio_bus)
		persistence_audio_player.position = location
		persistence_audio_player.stream = sound_effect.audio_stream
		persistence_audio_player.volume_db = sound_effect.sound_volume
		persistence_audio_player.pitch_scale = sound_effect.sound_pitch
		persistence_audio_player.pitch_scale += _rng.randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness)
		persistence_audio_player.play()
	else:
		push_error("Audio Manager failed to find setting for type ", SoundEffectDetails.enum_to_string(type))


func create_audio(type: SoundEffectDetails.SoundEffectType, destination_audio_bus: SoundEffectDetails.DestinationAudioBus = SoundEffectDetails.DestinationAudioBus.MASTER) -> void:
	if sound_effect_dict.has(SoundEffectDetails.enum_to_string(type)):
		var sound_effect: SoundEffectDetails = sound_effect_dict[SoundEffectDetails.enum_to_string(type)]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)
			new_audio.bus = SoundEffectDetails.destination_audio_bus_to_string(destination_audio_bus)
			new_audio.stream = sound_effect.audio_stream
			new_audio.volume_db = sound_effect.sound_volume
			new_audio.pitch_scale = sound_effect.sound_pitch
			new_audio.pitch_scale += _rng.randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness)
			new_audio.finished.connect(sound_effect.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", SoundEffectDetails.enum_to_string(type))

func fade_music(music_clip: AudioStream, volume_clip_linear: float,time_to_fade: float) -> void:
	var time_elapsed: float = 0.0
	if is_music_clip1_playing:
		first_audio_stream.stream = null
		first_audio_stream.stream = music_clip
		first_audio_stream.volume_db = linear_to_db(volume_clip_linear)
		first_audio_stream.play()
		while time_elapsed < time_to_fade:
			time_elapsed += delta_time
			first_audio_stream.volume_db = lerpf(-80.0, linear_to_db(volume_clip_linear), time_elapsed / time_to_fade)
			second_audio_stream.volume_db = lerpf(linear_to_db(volume_clip_linear), -80.0, time_elapsed / time_to_fade)
			await get_tree().process_frame
		second_audio_stream.stop()
	else:
		second_audio_stream.stream = null
		second_audio_stream.stream = music_clip
		second_audio_stream.volume_db = linear_to_db(volume_clip_linear)
		second_audio_stream.play()
		while time_elapsed < time_to_fade:
			time_elapsed += delta_time
			second_audio_stream.volume_db = lerpf(-80.0, linear_to_db(volume_clip_linear), time_elapsed / time_to_fade)
			first_audio_stream.volume_db = lerpf(linear_to_db(volume_clip_linear), -80.0, time_elapsed / time_to_fade)
			await get_tree().process_frame
		first_audio_stream.stop()

#region Setters and Signals
func set_player_sfx_volume(volume_linear: float) -> void:
	_player_sfx_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(player_sfx_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(player_sfx_bus_index, linear_to_db(volume_linear))

func set_weapons_volume(volume_linear: float) -> void:
	_weapons_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(weapons_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(weapons_bus_index, linear_to_db(volume_linear))

func set_master_volume(volume_linear: float) -> void:
	_master_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(master_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(volume_linear))

func set_music_volume(volume_linear: float) -> void:
	_music_volume = volume_linear
	if _music_volume == 0.0:
		AudioServer.set_bus_volume_db(music_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(_music_volume))

func set_sfx_volume(volume_linear: float) -> void:
	_sfx_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(sfx_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(volume_linear))

func change_music_clip(music: MusicDetails, time_to_fade: float = 2.2) -> void:
	music_clip_changed.emit(music, time_to_fade)
#endregion
