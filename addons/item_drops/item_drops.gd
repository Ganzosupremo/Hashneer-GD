@tool
extends EditorPlugin
## Loads the plugin by registering class names and
## adding signal bus(s) to the project autoload list

func _exit_tree():
	# Remove the old singleton if it exists
	if Engine.has_singleton("ItemDropsBus"):
		self.remove_autoload_singleton("ItemDropsBus")
