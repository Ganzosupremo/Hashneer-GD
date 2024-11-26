class_name Utils extends Node

static func build_res_from_dictionary(data: Dictionary, type: Resource):
	var res:= type
	for i in range(data.size()):
		var key = data.keys()[i]
		var value = data.values()[i]
		res.set(key, value)
	return res
