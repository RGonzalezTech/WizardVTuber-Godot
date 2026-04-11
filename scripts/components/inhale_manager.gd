class_name InhaleManager
extends Node

## Controls the ember glow cycle and associated smoke particle effects.
##
## This controller puppeteers the [EmberManager]'s [code]brightness[/code] API
## and toggles the [GPUParticles2D] smoke systems according to a timed state
## machine, keeping timing/smoke concerns out of the view layer.
##
## Cycle:
##   1. DIM  (5s) — dim oscillating glow, continuous smoke emitting.
##   2. BRIGHT (1s) — max brightness, smoke suppressed.
##   3. Transition — burst smoke fires once, then loops back to DIM.

enum EmberState {
	DIM, ## Dim oscillating glow; continuous smoke is emitting.
	BRIGHT, ## Max intensity glow; smoke is suppressed.
}

# --- Exports ---

## The EmberManager whose brightness this controller drives.
@export var ember_manager: EmberManager

## Continuous smoke emitted during the dim glow phase.
@export var dim_smoke: GPUParticles2D
## One-shot smoke burst emitted when transitioning out of the bright phase.
@export var burst_smoke: GPUParticles2D

## Duration in seconds for the dim glow phase.
@export var dim_duration: float = 5.0
## Duration in seconds for the max intensity phase.
@export var bright_duration: float = 1.0

## Whether the embers should oscillate in brightness during the dim phase.
@export var oscillation_enabled: bool = true
## The speed of the brightness oscillation during the dim phase.
@export var oscillation_speed: float = 2.0

# --- Private ---

var _state_timer: float = 0.0
var _time: float = 0.0
var _current_state: EmberState = EmberState.DIM
var _is_first_run: bool = true


func _ready() -> void:
	assert(is_instance_valid(ember_manager), "EmberManager is not set.")
	assert(is_instance_valid(dim_smoke), "Dim smoke node is not set.")
	assert(is_instance_valid(burst_smoke), "Burst smoke node is not set.")
	_enter_dim_state()


func _process(delta: float) -> void:
	_state_timer += delta

	match _current_state:
		EmberState.DIM:
			_process_dim_state(delta)
		EmberState.BRIGHT:
			_process_bright_state()


# --- State Processors ---

func _process_dim_state(delta: float) -> void:
	if oscillation_enabled:
		_time += delta
		ember_manager.brightness = _calculate_dim_brightness()

	if _state_timer >= dim_duration:
		_enter_bright_state()


func _process_bright_state() -> void:
	if _state_timer >= bright_duration:
		_enter_dim_state()


# --- State Transitions ---

func _enter_dim_state() -> void:
	_current_state = EmberState.DIM
	_state_timer = 0.0
	_time = 0.0

	dim_smoke.emitting = true

	# Fire the burst only on real transitions, not on startup.
	if not _is_first_run:
		burst_smoke.restart()

	_is_first_run = false


func _enter_bright_state() -> void:
	_current_state = EmberState.BRIGHT
	_state_timer = 0.0

	dim_smoke.emitting = false
	ember_manager.brightness = 1.0


# --- Helpers ---

func _calculate_dim_brightness() -> float:
	# Sine wave oscillating between 0.0 and 0.4 — the "dim" visual range.
	# Offset by PI/2 so the oscillation starts at 0 on state entry.
	var full_wave := (sin(_time * oscillation_speed - PI / 2.0) + 1.0) / 2.0
	return 0.22 + (full_wave * 0.4) # 0.22 to 0.62
