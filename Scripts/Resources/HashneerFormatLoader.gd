class_name HashneerFormatLoader extends ResourceFormatLoader

func _init():
    pass

func _get_recognized_extensions() -> PackedStringArray:
    return ["hashneer", "nigga"]

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
        var resource = _build_res_from_dictionary(dict.result, Resource.new())
        return resource
    return null

func _build_res_from_dictionary(data: Dictionary, type: Resource) -> Resource:
    var res = type
    for key in data.keys():
        var value = data[key]
        if typeof(value) == TYPE_DICTIONARY:
            var sub_res = _build_res_from_dictionary(value, type.new())
            res.set(key, sub_res)
        elif typeof(value) == TYPE_ARRAY:
            var array_res = []
            for item in value:
                if typeof(item) == TYPE_DICTIONARY:
                    array_res.append(_build_res_from_dictionary(item, type.new()))
                else:
                    array_res.append(item)
            res.set(key, array_res)
        else:
            res.set(key, value)
    return res

func _get_dependencies(path: String, add_types: bool) -> PackedStringArray:
    return []

func _rename_dependencies(path: String, renames: Dictionary) -> Error:
    return OK