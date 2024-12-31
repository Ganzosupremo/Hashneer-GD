class_name HashneerFormatLoader extends ResourceFormatLoader

func _init():
    pass

func _get_recognized_extensions() -> PackedStringArray:
    return ["hashneer"]

func _handles_type(type: StringName) -> bool:
    return ClassDB.is_parent_class(type, "Resource")

func _load(path: String, original_path: String = "", use_sub_threads: bool = false, cache_mode: int = 0):
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return FileAccess.get_open_error()
    var data = file.get_as_text()
    file.close()
    var json = JSON.new()
    var dict = json.parse(data)
    if dict.error == OK:
        var resource = Utils.build_res_from_dictionary(dict.result, Resource.new())
        return resource
    return null

func _get_dependencies(path: String, add_types: bool) -> PackedStringArray:
    return []

func _rename_dependencies(path: String, renames: Dictionary) -> Error:
    return OK