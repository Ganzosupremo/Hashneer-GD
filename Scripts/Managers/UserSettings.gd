extends Node

signal settings_changed(settings_name: String, value: Variant)


var _defaults: Dictionary = {
        "video": {
                "resolution": {
                        "window_size": Vector2i(1920,1080),
                        "index": 0
                },
                "fullscreen": false,
                "vsync": true
        },
        "audio": {
                "master_volume": 1.0,
                "music_volume": 1.0,
                "sfx_volume": 1.0,
                "player_sfx_volume": 1.0,
                "weapons_volume": 1.0
        }
}

var _settings: Dictionary = {}

const SETTINGS_FILE_PATH: String = "user://settings.cfg"

func _ready() -> void:
        _settings = _defaults.duplicate(true)
        
        # Convert default Vector2i to string format
        var default_res = _defaults.video.resolution.window_size
        _settings.video.resolution.window_size = "%dx%d" % [default_res.x, default_res.y]

        load_settings()
        apply_all_settings()

func load_settings() -> void:
        var config: ConfigFile = ConfigFile.new()
        var error = config.load(SETTINGS_FILE_PATH)

        if error != OK:
                print("Failed to load settings file: ", error)
                return
        
        if config.has_section("video"):
                var res_x = config.get_value("video", "resolution_x", _defaults.video.resolution.window_size.x)
                var res_y = config.get_value("video", "resolution_y", _defaults.video.resolution.window_size.y)
                _settings.video.resolution.window_size = "%dx%d" % [res_x, res_y]
                _settings.video.resolution.index = config.get_value("video", "resolution_index", _defaults.video.resolution.index)
                _settings.video.fullscreen = config.get_value("video", "fullscreen", _defaults.video.fullscreen)
                _settings.video.vsync = config.get_value("video", "vsync", _defaults.video.vsync)
        if config.has_section("audio"):
                _settings.audio.master_volume = config.get_value("audio", "master_volume", _defaults.audio.master_volume)
                _settings.audio.music_volume = config.get_value("audio", "music_volume", _defaults.audio.music_volume)
                _settings.audio.sfx_volume = config.get_value("audio", "sfx_volume", _defaults.audio.sfx_volume)
                _settings.audio.player_sfx_volume = config.get_value("audio", "player_sfx_volume", _defaults.audio.player_sfx_volume)
                _settings.audio.weapons_volume = config.get_value("audio", "weapons_volume", _defaults.audio.weapons_volume)

func save_settings() -> void:
        var config: ConfigFile = ConfigFile.new()
        var size = _settings.video.resolution.window_size.split("x")
        var res: Vector2i = Vector2i(size[0].to_int(), size[1].to_int())
        config.set_value("video", "resolution_x", res.x)
        config.set_value("video", "resolution_y", res.y)
        config.set_value("video", "resolution_index", _settings.video.resolution.index)
        config.set_value("video", "fullscreen", _settings.video.fullscreen)
        config.set_value("video", "vsync", _settings.video.vsync)
        
        config.set_value("audio", "master_volume", _settings.audio.master_volume)
        config.set_value("audio", "music_volume", _settings.audio.music_volume)
        config.set_value("audio", "sfx_volume", _settings.audio.sfx_volume)
        config.set_value("audio", "player_sfx_volume", _settings.audio.player_sfx_volume)
        config.set_value("audio", "weapons_volume", _settings.audio.weapons_volume)

        var error = config.save(SETTINGS_FILE_PATH)
        if error != OK:
                print("Failed to save settings file: ", error)

func apply_all_settings() -> void:
        var size: Array = _settings.video.resolution.window_size.split("x")
        var res: Vector2i = Vector2i(size[0].to_int(), size[1].to_int())
        apply_resolution(res)
        apply_fullscreen(_settings.video.fullscreen)
        apply_vsync(_settings.video.vsync)

        # Apply audio settings
        AudioManager.set_master_volume(_settings.audio.master_volume)
        AudioManager.set_music_volume(_settings.audio.music_volume)
        AudioManager.set_sfx_volume(_settings.audio.sfx_volume)
        AudioManager.set_player_sfx_volume(_settings.audio.player_sfx_volume)
        AudioManager.set_weapons_volume(_settings.audio.weapons_volume)

#region Getters and Setters
func get_resolution() -> Vector2i:
        return _settings.video.resolution

func get_resolution_index() -> int:
        return _settings.video.resolution.index

func is_fullscreen() -> bool:
        return _settings.video.fullscreen

func is_vsync_enabled() -> bool:
        return _settings.video.vsync

func get_master_volume() -> float:
        return _settings.audio.master_volume

func get_music_volume() -> float:
        return _settings.audio.music_volume

func get_sfx_volume() -> float:
        return _settings.audio.sfx_volume

func get_player_sfx_volume() -> float:
        return _settings.audio.player_sfx_volume

func get_weapons_volume() -> float:
        return _settings.audio.weapons_volume

# Setting setters
func set_resolution(res: Vector2i, index: int) -> void:
        _settings.video.resolution.window_size = "%dx%d" % [res.x, res.y]
        _settings.video.resolution.index = index
        apply_resolution(res)
        save_settings()
        settings_changed.emit("resolution", res)

func set_fullscreen(enabled: bool) -> void:
        _settings.video.fullscreen = enabled
        apply_fullscreen(enabled)
        save_settings()
        settings_changed.emit("fullscreen", enabled)

func set_vsync(enabled: bool) -> void:
        _settings.video.vsync = enabled
        apply_vsync(enabled)
        save_settings()
        settings_changed.emit("vsync", enabled)

func set_master_volume(volume: float) -> void:
        _settings.audio.master_volume = volume
        AudioManager.set_master_volume(volume)
        save_settings()
        settings_changed.emit("master_volume", volume)

func set_music_volume(volume: float) -> void:
        _settings.audio.music_volume = volume
        AudioManager.set_music_volume(volume)
        save_settings()
        settings_changed.emit("music_volume", volume)

func set_sfx_volume(volume: float) -> void:
        _settings.audio.sfx_volume = volume
        AudioManager.set_sfx_volume(volume)
        save_settings()
        settings_changed.emit("sfx_volume", volume)

func set_player_sfx_volume(volume: float) -> void:
        _settings.audio.player_sfx_volume = volume
        AudioManager.set_player_sfx_volume(volume)
        save_settings()
        settings_changed.emit("player_sfx_volume", volume)

func set_weapons_volume(volume: float) -> void:
        _settings.audio.weapons_volume = volume
        AudioManager.set_weapons_volume(volume)
        save_settings()
        settings_changed.emit("weapons_volume", volume)

func set_window_mode(mode: DisplayServer.WindowMode) -> void:
        apply_window_mode(mode)
        save_settings()
        settings_changed.emit("window_mode", mode)

func set_window_flags(flags: DisplayServer.WindowFlags, enable_flag: bool = true) -> void:
        apply_window_flags(flags, enable_flag)
        save_settings()
        settings_changed.emit("window_flags", flags)

#endregion

#region Apply functions
func apply_resolution(res: Vector2i) -> void:
        DisplayServer.window_set_size(res)

func apply_fullscreen(enabled: bool) -> void:
        if enabled:
                DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
        else:
                DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)

func apply_vsync(enabled: bool) -> void:
        if enabled:
                DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
        else:
                DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func apply_window_mode(mode: DisplayServer.WindowMode) -> void:
        DisplayServer.window_set_mode(mode)

func apply_window_flags(flag: DisplayServer.WindowFlags, enable_flag: bool = true) -> void:
        DisplayServer.window_set_flag(flag, enable_flag)
#endregion
