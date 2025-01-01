class_name HashneerFormatSaver extends ResourceFormatSaver

func _init():
    pass

func _get_recognized_extensions(_resource: Resource) -> PackedStringArray:
    return ["hashneer", "nigga"]

func save(path: String, resource: Resource, flags: int = 0) -> Error:
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return FileAccess.get_open_error()
    
    var dict = _build_dictionary_from_res(resource)
    var data_to_store = JSON.stringify(dict)
    file.store_string(data_to_store)
    file.close()
    return OK

func _build_dictionary_from_res(res: Resource) -> Dictionary:
    var data = {}
    for property in res.get_property_list():
        var key = property.name
        var value = res.get(key)
        if typeof(value) == TYPE_OBJECT and value is Resource:
            data[key] = _build_dictionary_from_res(value)
        elif typeof(value) == TYPE_ARRAY:
            var array_data = []
            for item in value:
                if typeof(item) == TYPE_OBJECT and item is Resource:
                    array_data.append(_build_dictionary_from_res(item))
                else:
                    array_data.append(item)
            data[key] = array_data
        else:
            data[key] = value
    return data
