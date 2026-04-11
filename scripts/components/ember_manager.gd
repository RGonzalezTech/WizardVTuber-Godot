class_name EmberManager
extends Node2D

## This node is responsible for managing the pipe contents and whether they are
## lit or how bright the embers are.
##
## It is a "dumb" visual component. The [code]brightness[/code] property is the
## public API; external controllers (e.g. InhaleManager) are responsible for
## driving it.

## Controls the opacity of the lit embers.
@export_range(0, 1, 0.01) var brightness: float = 0.0:
	set(value):
		brightness = value
		_update_ember_sprite()

## The sprite to control the brightness of.
@export var lit_sprite: Sprite2D


func _ready() -> void:
	assert(is_instance_valid(lit_sprite), "Lit sprite is not set.")
	_update_ember_sprite()


func _update_ember_sprite() -> void:
	if not is_instance_valid(lit_sprite):
		return
	lit_sprite.modulate = Color(1, 1, 1, brightness)