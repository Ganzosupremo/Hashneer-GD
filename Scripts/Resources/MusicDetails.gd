class_name MusicDetails extends Resource

@export var music_clip: AudioStream
@export_range(0.0, 1.0, 0.05) var volume_linear: float = 0.5
## Check if this music details should play a playlist
@export var has_playlist: bool = false
## The playlist to play
@export var playlist: AudioStreamPlaylist
