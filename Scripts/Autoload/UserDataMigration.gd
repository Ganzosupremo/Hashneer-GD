extends Node
## Moves the player's saves and settings from the old user data folder to the new one.
##
## The project used to store its data in a folder with an offensive name. The folder was renamed
## (see [code]application/config/custom_user_dir_name[/code]), so existing players would lose their saves.
## This autoload runs first, before the settings and saves are read, and copies the old files once.

## Name of the old user data folder, only kept so old saves can be found.
const LEGACY_USER_DIR_NAME: String = "Nigga_pls"
## The old default save file, it never held a real save slot.
const LEGACY_DEFAULT_SAVE: String = "NOT_A_SAVE_FILE_NIGGA.sav"
const SETTINGS_FILE: String = "settings.cfg"
const SAVES_DIR: String = "saves"


func _init() -> void:
	var old_dir: String = OS.get_data_dir().path_join(LEGACY_USER_DIR_NAME)
	var new_dir: String = OS.get_user_data_dir()
	if old_dir == new_dir or !DirAccess.dir_exists_absolute(old_dir): return
	if _has_user_data(new_dir): return

	var copied: int = 0
	if FileAccess.file_exists(old_dir.path_join(SETTINGS_FILE)):
		copied += _copy(old_dir.path_join(SETTINGS_FILE), new_dir.path_join(SETTINGS_FILE))

	var old_saves: String = old_dir.path_join(SAVES_DIR)
	if DirAccess.dir_exists_absolute(old_saves):
		DirAccess.make_dir_recursive_absolute(new_dir.path_join(SAVES_DIR))
		for file_name in DirAccess.get_files_at(old_saves):
			if file_name == LEGACY_DEFAULT_SAVE: continue
			copied += _copy(old_saves.path_join(file_name), new_dir.path_join(SAVES_DIR).path_join(file_name))

	print("UserDataMigration: copied %d files from the old user data folder." % copied)

## Returns [code]true[/code] if the new folder already has settings or save slots, so nothing is overwritten.
func _has_user_data(dir: String) -> bool:
	if FileAccess.file_exists(dir.path_join(SETTINGS_FILE)): return true
	var saves: String = dir.path_join(SAVES_DIR)
	if !DirAccess.dir_exists_absolute(saves): return false
	for file_name in DirAccess.get_files_at(saves):
		if file_name.ends_with(".sav"): return true
	return false

func _copy(from: String, to: String) -> int:
	var error: Error = DirAccess.copy_absolute(from, to)
	if error != OK:
		push_error("UserDataMigration: could not copy %s (error %d)" % [from, error])
		return 0
	return 1
