class_name EmberManager
extends Node2D

## This node is responsible for managing the pipe contents and whether they are
## lit or how bright the embers are.

## Controls the opacity of the lit embers.
@export_range(0, 1, 0.01) var brightness: float = 0.0:
    set(value):
        brightness = value
        _update_ember_sprite()

## The sprite to control the brightness of.
@export var lit_sprite: Sprite2D

## Whether the embers should oscillate in brightness.
@export var oscillation_enabled: bool = true
## The speed of the oscillation.
@export var oscillation_speed: float = 2.0

var _time: float = 0.0

func _ready() -> void:
    assert(is_instance_valid(lit_sprite), "Lit sprite is not set.")
    _update_ember_sprite()


func _process(delta: float) -> void:
    if not oscillation_enabled:
        return
    
    _time += delta
    _update_oscillation()


func _update_oscillation() -> void:
    # Shifts the sine wave upwards and scales it to oscillate between 0 and 1.
    # Offsets by PI/2 so it starts at 0 brightness.
    brightness = (sin(_time * oscillation_speed - PI / 2.0) + 1.0) / 2.0


func _update_ember_sprite() -> void:
    lit_sprite.modulate = Color(1, 1, 1, brightness)