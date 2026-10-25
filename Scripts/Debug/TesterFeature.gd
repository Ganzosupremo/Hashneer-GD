class_name TesterFeature extends RefCounted
## One action that the in-game Feature Tester can run.
##
## A feature belongs to a [member category] (the section it is listed in) and to the game
## [member modes] where it makes sense. Leave [member modes] empty to show it everywhere.[br]
## Register features with [code]FeatureTester.add_action()[/code] or [code]FeatureTester.add_toggle()[/code].

const MINING: StringName = &"mining"
const WAVES: StringName = &"waves"
const MENU: StringName = &"menu"
## Both game modes, for features that need a player in the level.
const GAMEPLAY: Array[StringName] = [MINING, WAVES]

var category: String = ""
var label: String = ""
var tooltip: String = ""
## Game modes where the feature is listed, empty means every mode.
var modes: Array[StringName] = []
## Called when the feature's button is pressed.
var action: Callable
## Returns the on/off state for toggle features, leave it invalid for plain buttons.
var toggle_state: Callable

func is_available_in(mode: StringName) -> bool:
	return modes.is_empty() or modes.has(mode)

func is_toggle() -> bool:
	return toggle_state.is_valid()

func is_on() -> bool:
	return is_toggle() and toggle_state.call()
