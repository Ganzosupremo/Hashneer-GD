extends Node2D

signal music_volume_changed(volume_db: float)
signal music_clip_changed(music: MusicDetails, time_to_fade: float)

@onready var first_audio_stream: AudioStreamPlayer = $FirstAudioStream
@onready var second_audio_stream: AudioStreamPlayer = $SecondAudioStream

@export var main_game_mixer: AudioBusLayout

var current_music_clip: AudioStream
var is_music_clip1_playing: bool = true
var delta_time: float = 0.0
@export_range(0.0, 1.0, 0.05) var music_volume: float = .5:
	get:
		return _music_volume
	set(value):
		_music_volume = value
		set_music_volume(value)
	
var _music_volume: float = 0.5

func _ready() -> void:
	music_clip_changed.connect(_on_music_clip_changed)
	set_music_volume(music_volume)

func _process(delta: float) -> void:
	delta_time = delta

func _on_music_clip_changed(clip: MusicDetails, time_to_fade: float) -> void:
	if clip == null:
		return
	
	current_music_clip = clip.music_clip
	is_music_clip1_playing = !is_music_clip1_playing
	await fade_music(clip.music_clip, clip.volume_linear, time_to_fade)

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

func set_music_volume(volume_linear: float) -> void:
	_music_volume = volume_linear
	if _music_volume == 0.0:
		AudioServer.set_bus_volume_db(1, -80)
	else:
		AudioServer.set_bus_volume_db(1, mlinear_to_db(_music_volume))
	
	music_volume_changed.emit(mlinear_to_db(_music_volume))

func set_sfx_volume(volume_linear: float) -> void:
	if volume_linear == 0:
		AudioServer.set_bus_volume_db(2, -80)
	else:
		AudioServer.set_bus_volume_db(2, mlinear_to_db(volume_linear))

func change_music_clip(music: MusicDetails, time_to_fade: float = 2.2) -> void:
	music_clip_changed.emit(music, time_to_fade)

func mlinear_to_db(value: float) -> float:
	var linear_scale_range: float = 20.0
	var v: float = 20.0 * log(value) / log(10)
	var uv: float = linear_to_db(value)
	print("volume with Godot function ", uv)
	print("volume with own function", v)
	
	return v
