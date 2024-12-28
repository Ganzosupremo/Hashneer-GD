class_name Utils extends Node

static func build_res_from_dictionary(data: Dictionary, type: Resource) -> Resource:
	var res:= type
	for i in range(data.size()):
		var key = data.keys()[i]
		var value = data.values()[i]
		res.set(key, value)
	return res

"""Sets the properties of the TweenableButton automatically to the child AnimationComponent.
I'm lazy to do it manually."""
static func copy_properties(parent: Node, child: Node) -> void:
	if parent.has_method("get_properties") and child.has_method("set_properties"):
		var parent_properties = parent.call("get_properties")
		child.call("set_properties", parent_properties)
	
