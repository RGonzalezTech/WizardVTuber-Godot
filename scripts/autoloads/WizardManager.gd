class_name WizardManagerCode
extends Node

const WIZARD_RENDERER: PackedScene = preload("res://scenes/wizard/WizardRenderer.tscn")

## The active window (or null)
var active_renderer: Window = null

func is_window_open() -> bool:
	return is_instance_valid(active_renderer)

## Creates a new window for rendering stuff
func create_window() -> Window:
	if is_window_open():
		return active_renderer

	active_renderer = Window.new()
	active_renderer.title = "VTuberRenderer"
	active_renderer.size = Vector2i(800, 800)
	active_renderer.transparent = true
	
	# Required: Handle the close button (X)
	active_renderer.close_requested.connect(_on_window_close_requested)

	# Populte the window
	var renderer = WIZARD_RENDERER.instantiate()
	active_renderer.add_child(renderer)
	
	add_child(active_renderer)
	active_renderer.show() # Make sure it's visible
	active_renderer.move_to_center()
	return active_renderer

## Closes and cleans up the active window
func close_window() -> void:
	if not is_window_open():
		return
	active_renderer.queue_free()
	active_renderer = null

## Internal handler so we can null out active_renderer when closed via the X button
func _on_window_close_requested() -> void:
	close_window()
