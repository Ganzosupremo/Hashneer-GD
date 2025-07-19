class_name Debugger
extends Node2D

## Toggle this to enable/disable all debug messages
const DEBUG_ENABLED: bool = true

## ANSI color codes for console output (works in Godot's output)
const COLORS : Dictionary= {
	"DEFAULT": "",
	"WARNING": "[color=yellow]",
	"ERROR": "[color=red]",
	"SUCCESS": "[color=green]"
}

## Static method to print normal debug messages
static func print(args) -> void:
	if not DEBUG_ENABLED:
		return
	print_rich(args)

## Static method to print warning messages
static func print_warning(args) -> void:
	if not DEBUG_ENABLED:
		return
	print_rich(COLORS.WARNING + "WARNING: " + args)

## Static method to print error messages
static func print_error(args) -> void:
	if not DEBUG_ENABLED:
		return
	print_rich(COLORS.ERROR + "ERROR: " + args)

## Static method to print success messages
static func print_success(args) -> void:
	if not DEBUG_ENABLED:
		return
	print_rich(COLORS.SUCCESS + "SUCCESS: " + args)
