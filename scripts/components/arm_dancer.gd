class_name ArmDancer
extends Node2D

## Makes the arm bounce up and down like a puppet dancing.
## Pure vertical oscillation — no horizontal drift or rotation.

@export_group("Bobbing")
## How far the arm bobs up/down (pixels).
@export var bob_amplitude: float = 3.0
## Bobbing speed — beats per second.
@export var bob_speed: float = 3.0
## Phase offset (0–1) so left/right arms can alternate.
@export_range(0.0, 1.0) var phase: float = 0.0

## If true, only dance while typing; otherwise always dance.
@export var only_when_typing: bool = true

var _base_position: Vector2
var _elapsed: float = 0.0


func _ready() -> void:
	_base_position = position
	CompanionListener.typing_changed.connect(_on_typing_changed)


func _process(delta: float) -> void:
	if only_when_typing and not CompanionListener.is_typing:
		# Smoothly return to base when not typing
		position = position.lerp(_base_position, 8.0 * delta)
		return

	_elapsed += delta

	var bob := sin((_elapsed + phase) * bob_speed * TAU) * bob_amplitude
	position = _base_position + Vector2(0, bob)


func _on_typing_changed(_is_typing: bool) -> void:
	if only_when_typing and _is_typing:
		_elapsed = 0.0
		# Re-snapshot base in case CursorTracker moved the arm while idle
		_base_position = position
