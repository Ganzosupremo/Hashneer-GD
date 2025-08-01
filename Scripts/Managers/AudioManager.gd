class_name SFXManager extends Node2D
## AudioManager: Manages all audio in the game, including sound effects and music. Autoload this script as "AudioManager" for global access. [br]
##
## This script handles the creation and management of sound effects and music in the game.
## It allows for playing sound effects at specific locations, changing music clips, and managing audio buses.
## It also provides functionality for fading music in and out, and adjusting audio volumes for different categories
## such as music, sound effects, player sound effects, and weapons.

## 
signal music_clip_changed(music: MusicDetails, time_to_fade: float)

## The audio buses used in the game.
## These buses are used to route audio to different channels in the audio system.
enum DestinationAudioBus {
	MASTER = 0, ## The master audio bus, used for overall volume control.
	PLAYER_SFX = 1, ## The audio bus for player sound effects, such as footsteps.
	SFX = 2, ## The audio bus for general sound effects, such as explosions and UI sounds.
	MUSIC = 3, ## The audio bus for music, used for background music tracks.
	WEAPONS = 4, ## The audio bus for weapon sounds, such as gunfire and reloads.
}

## The audio bus layout for the main game mixer.
@export var main_game_mixer: AudioBusLayout
## Stores all possible SoundEffects that can be played.
@export var sound_effects: Array[SoundEffectDetails]
## The music volume in linear value. 
@export_range(0.0, 1.0, 0.1) var music_volume: float = .5:
	get:
		return _music_volume
	set(value):
		_music_volume = value
## The master volume in linear value.
@export_range(0.0, 1.0, 0.1) var master_volume: float = .5:
	get:
		return _master_volume
	set(value):
		_master_volume = value
## The sound effects volume in linear value.
@export_range(0.0, 1.0, 0.1) var sfx_volume: float = .5:
	get:
		return _sfx_volume
	set(value):
		_sfx_volume = value
## The player sound effects volume in linear value.
@export_range(0.0, 1.0, 0.1) var player_sfx_volume: float = .5:
	get:
		return _player_sfx_volume
	set(value):
		_player_sfx_volume = value
## The weapons volume in linear value.
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

var _current_music_clip: AudioStream
var _is_music_clip1_playing: bool = true
var _delta_time: float = 0.0
var _sound_effect_dict: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _first_audio_stream: AudioStreamPlayer = $FirstAudioStream
@onready var _second_audio_stream: AudioStreamPlayer = $SecondAudioStream

@onready var _music_bus_index: int = AudioServer.get_bus_index("Music")
@onready var _sfx_bus_index: int = AudioServer.get_bus_index("SFX")
@onready var _player_sfx_bus_index: int = AudioServer.get_bus_index("Player SFX")
@onready var _weapons_bus_index: int = AudioServer.get_bus_index("Weapons")
@onready var _master_bus_index: int = AudioServer.get_bus_index("Master")

func _ready() -> void:
	_rng.randomize()
	for sound_effect in sound_effects:
		_sound_effect_dict[SoundEffectDetails.sound_effect_type_to_string(sound_effect.sound_type)] = sound_effect
	music_clip_changed.connect(_on_music_clip_changed)
	set_music_volume(music_volume)

func _process(delta: float) -> void:
	_delta_time = delta

func _on_music_clip_changed(clip: MusicDetails, time_to_fade: float) -> void:
	if clip == null:
		return
	
	_current_music_clip = clip.music_clip
	_is_music_clip1_playing = !_is_music_clip1_playing
	
	var to_play: AudioStream = clip.music_clip if !clip.has_playlist else clip.playlist
	await _fade_music(to_play, clip.volume_linear, time_to_fade)

## Creates a sound effect at a specific location if the limit has not been reached.
## This function will create a 2D audio player that will play the sound effect at the location.
## The audio player will be destroyed when the sound effect is finished playing.
## The audio bus will be set to the correct one based on the [param destination_audio_bus].
## If the sound effect limit has been reached, the function will not create a new audio player.
## If the sound effect type is not found in the _sound_effect_dict, an error will be logged.
## [br]
## Parameters:[br]
## [param location] is the global position of the audio effect, as a Vector2.[br]
## [param type] is the SoundEffectDetails.SoundEffectType to be played.
## The available sound effect types are defined in SoundEffectDetails.SoundEffectType.[br]
## [param destination_audio_bus] is the audio bus to play the sound effect on, defaulting to MASTER.
## The available audio buses are defined in SoundEffectDetails.DestinationAudioBus.
## The audio bus can be set to MASTER, SFX, PLAYER_SFX, or WEAPONS.[br]
## Example usage:[br]
## [codeblock]
## create_2d_audio_at_location(Vector2(100, 100), SoundEffectDetails.SoundEffectType.EXPLOSION, SoundEffectDetails.DestinationAudioBus.SFX)
## [/codeblock]
## This will create a 2D audio player at the position (100, 100)
## that plays the EXPLOSION sound effect on the SFX audio bus.
## [br]
## Note: The sound effect must have an open limit to be played.
func create_2d_audio_at_location(location: Vector2, type: SoundEffectDetails.SoundEffectType, destination_audio_bus: DestinationAudioBus = DestinationAudioBus.MASTER) -> void:
	if _sound_effect_dict.has(SoundEffectDetails.sound_effect_type_to_string(type)):
		var sound_effect: SoundEffectDetails = _sound_effect_dict[SoundEffectDetails.sound_effect_type_to_string(type)]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_2D_audio: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			add_child(new_2D_audio)
			# Set the audio bus to the correct one
			new_2D_audio.bus = destination_audio_bus_to_string(destination_audio_bus)
			new_2D_audio.position = location
			new_2D_audio.stream = sound_effect.audio_stream
			new_2D_audio.volume_db = sound_effect.sound_volume
			new_2D_audio.pitch_scale = sound_effect.sound_pitch
			new_2D_audio.pitch_scale += _rng.randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness)
			new_2D_audio.finished.connect(sound_effect.on_audio_finished)
			new_2D_audio.finished.connect(new_2D_audio.queue_free)
			new_2D_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", SoundEffectDetails.sound_effect_type_to_string(type))

## @deprecated: Use `create_2d_audio_at_location` instead.
var persistence_audio_player: AudioStreamPlayer2D 

## @deprecated: use [member create_2d_audio_at_location] instead.[br]
## Creates a sound effect at a specific location if the limit has not been reached.
## Pass [param location] for the global position of the audio effect, and [param type] for the SoundEffectDetails to be queued.
## This function will create a persistent audio player that will play the sound effect at the location.
## This is useful for sound effects that need to be played at a specific location, such as footsteps or gunfire.
## The audio player won't be destroyed when the sound effect is finished playing.
func create_2d_audio_at_location_with_persistent_player(location: Vector2, type: SoundEffectDetails.SoundEffectType, destination_audio_bus: DestinationAudioBus = DestinationAudioBus.MASTER):
	if _sound_effect_dict.has(SoundEffectDetails.sound_effect_type_to_string(type)):
		var sound_effect: SoundEffectDetails = _sound_effect_dict[SoundEffectDetails.sound_effect_type_to_string(type)]
		
		if !sound_effect.has_open_limit(): return
		
		sound_effect.change_audio_count(1)
		if persistence_audio_player == null:
			persistence_audio_player = AudioStreamPlayer2D.new()
			add_child(persistence_audio_player)
		persistence_audio_player.bus = destination_audio_bus_to_string(destination_audio_bus)
		persistence_audio_player.position = location
		persistence_audio_player.stream = sound_effect.audio_stream
		persistence_audio_player.volume_db = sound_effect.sound_volume
		persistence_audio_player.pitch_scale = sound_effect.sound_pitch
		persistence_audio_player.pitch_scale += _rng.randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness)
		persistence_audio_player.play()
	else:
		push_error("Audio Manager failed to find setting for type ", SoundEffectDetails.sound_effect_type_to_string(type))

## Creates a sound effect based on the [param type] and [param destination_audio_bus].
## This function will create a new AudioStreamPlayer and play the sound effect.
## The audio player will be destroyed when the sound effect is finished playing.
## The audio bus will be set to the correct one based on the [param destination_audio_bus].
## If the sound effect limit has been reached, the function will not create a new audio player.
## If the sound effect type is not found in the _sound_effect_dict, an error will be logged.
## [br]
## Parameters:[br]
## [param type] is the SoundEffectDetails.SoundEffectType to be played.
## The available sound effect types are defined in SoundEffectDetails.SoundEffectType.[br]
## [param destination_audio_bus] is the audio bus to play the sound effect on, defaulting to MASTER.
## The available audio buses are defined in SoundEffectDetails.DestinationAudioBus.
## The audio bus can be set to MASTER, SFX, PLAYER_SFX, or WEAPONS.[br]
## Example usage:[br]
## [codeblock]
## create_audio(SoundEffectDetails.SoundEffectType.EXPLOSION, SoundEffectDetails.DestinationAudioBus.SFX)
## [/codeblock]
## This will create a new audio player that plays the EXPLOSION sound effect on the SFX audio bus.
## [br]
## Note: The sound effect must have an open limit to be played.
func create_audio(type: SoundEffectDetails.SoundEffectType, destination_audio_bus: DestinationAudioBus = DestinationAudioBus.MASTER) -> void:
	if _sound_effect_dict.has(SoundEffectDetails.sound_effect_type_to_string(type)):
		var sound_effect: SoundEffectDetails = _sound_effect_dict[SoundEffectDetails.sound_effect_type_to_string(type)]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)
			new_audio.bus = destination_audio_bus_to_string(destination_audio_bus)
			new_audio.stream = sound_effect.audio_stream
			new_audio.volume_db = sound_effect.sound_volume
			new_audio.pitch_scale = sound_effect.sound_pitch
			new_audio.pitch_scale += _rng.randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness)
			new_audio.finished.connect(sound_effect.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", SoundEffectDetails.sound_effect_type_to_string(type))

func _fade_music(music_clip: AudioStream, volume_clip_linear: float,time_to_fade: float) -> void:
	var time_elapsed: float = 0.0
	if _is_music_clip1_playing:
		_first_audio_stream.stream = null
		_first_audio_stream.stream = music_clip
		_first_audio_stream.volume_db = linear_to_db(volume_clip_linear)
		_first_audio_stream.play()
		while time_elapsed < time_to_fade:
			time_elapsed += _delta_time
			_first_audio_stream.volume_db = lerpf(-80.0, linear_to_db(volume_clip_linear), time_elapsed / time_to_fade)
			_second_audio_stream.volume_db = lerpf(linear_to_db(volume_clip_linear), -80.0, time_elapsed / time_to_fade)
			await get_tree().process_frame
		_second_audio_stream.stop()
	else:
		_second_audio_stream.stream = null
		_second_audio_stream.stream = music_clip
		_second_audio_stream.volume_db = linear_to_db(volume_clip_linear)
		_second_audio_stream.play()
		while time_elapsed < time_to_fade:
			time_elapsed += _delta_time
			_second_audio_stream.volume_db = lerpf(-80.0, linear_to_db(volume_clip_linear), time_elapsed / time_to_fade)
			_first_audio_stream.volume_db = lerpf(linear_to_db(volume_clip_linear), -80.0, time_elapsed / time_to_fade)
			await get_tree().process_frame
		_first_audio_stream.stop()

## Converts a destination audio bus to a string.
static func destination_audio_bus_to_string(destination: DestinationAudioBus) -> String:
	return AudioServer.get_bus_name(destination)

#region Setters and Signals
## 
func set_player_sfx_volume(volume_linear: float) -> void:
	_player_sfx_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(_player_sfx_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(_player_sfx_bus_index, linear_to_db(volume_linear))
## Sets the weapons volume.
## This function sets the volume of the weapons audio bus.
## It takes a linear volume value between 0.0 and 1.0.
## If the volume is 0.0, the bus volume is set to -72 dB to effectively mute it.
## Otherwise, the bus volume is set to the linear volume converted to decibels.
## [br]
## Parameters:[br]
## [param volume_linear] is the linear volume value to set for the weapons audio bus.
## It should be a float value between 0.0 and 1.0.
func set_weapons_volume(volume_linear: float) -> void:
	_weapons_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(_weapons_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(_weapons_bus_index, linear_to_db(volume_linear))

## Sets the master volume.
## This function sets the volume of the master audio bus.
## It takes a linear volume value between 0.0 and 1.0.
## If the volume is 0.0, the bus volume is set to -72 dB to effectively mute it.
## Otherwise, the bus volume is set to the linear volume converted to decibels.
## [br]
## Parameters:[br]
## [param volume_linear] is the linear volume value to set for the master audio bus.
## It should be a float value between 0.0 and 1.0.
## This is used to control the overall volume of the game.
func set_master_volume(volume_linear: float) -> void:
	_master_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(_master_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(_master_bus_index, linear_to_db(volume_linear))

## Sets the music volume.
## This function sets the volume of the music audio bus.
## It takes a linear volume value between 0.0 and 1.0.
## If the volume is 0.0, the bus volume is set to -72 dB to effectively mute it.
## Otherwise, the bus volume is set to the linear volume converted to decibels.
## [br]
## Parameters:[br]
## [param volume_linear] is the linear volume value to set for the music audio bus.
## It should be a float value between 0.0 and 1.0.
func set_music_volume(volume_linear: float) -> void:
	_music_volume = volume_linear
	if _music_volume == 0.0:
		AudioServer.set_bus_volume_db(_music_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(_music_bus_index, linear_to_db(_music_volume))

## Sets the sound effects volume.
## This function sets the volume of the sound effects audio bus.
## It takes a linear volume value between 0.0 and 1.0.
## If the volume is 0.0, the bus volume is set to -72 dB to effectively mute it.
## Otherwise, the bus volume is set to the linear volume converted to decibels.
## [br]
## Parameters:[br]
## [param volume_linear] is the linear volume value to set for the sound effects audio bus.
## It should be a float value between 0.0 and 1.0.
func set_sfx_volume(volume_linear: float) -> void:
	_sfx_volume = volume_linear
	if volume_linear == 0.0:
		AudioServer.set_bus_volume_db(_sfx_bus_index, -72)
	else:
		AudioServer.set_bus_volume_db(_sfx_bus_index, linear_to_db(volume_linear))

## Changes the current music clip to a new one.
## This function emits the [signal music_clip_changed] signal with the new music details and fade time.
## It is used to change the music clip that is currently playing in the game.
## [br]
## Parameters:[br]
## [param music] is the MusicDetails resource that contains the new music clip and its properties.
## It should be a [MusicDetails] resource that has been preloaded or created.
## [param time_to_fade] is the time in seconds to fade the music in or out.
## Example usage:[br]
## [codeblock]
## var new_music: MusicDetails = preload("res://path/to/music.tres")
## AudioManager.change_music_clip(new_music, 2.5)
## [/codeblock]
## This will change the current music clip to the new one and fade it in over 2.5 seconds.
## [br]
## Note: The music clip must be a valid MusicDetails resource with a music clip or playlist.
## If the music clip is null, the function will not emit the signal or change the music.
func change_music_clip(music: MusicDetails, time_to_fade: float = 2.2) -> void:
	music_clip_changed.emit(music, time_to_fade)
#endregion
