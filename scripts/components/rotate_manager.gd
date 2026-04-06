class_name RotateManager
extends Node2D

## This node is responsible for rotating the pipe based on the audio input level.

@export_group("Rotation")
## The node to rotate (e.g. the pipe sprite or its parent).
@export var rotate_target: Node2D

## Rotation angle (in degrees) when audio is at or below the threshold.
## This is the resting (idle) angle.
@export_range(-180.0, 180.0, 0.5) var rotation_min_deg: float = -5.0

## Rotation angle (in degrees) at maximum audio volume (1.0).
@export_range(-180.0, 180.0, 0.5) var rotation_max_deg: float = 5.0

## How smoothly the rotation interpolates toward its target value.
## 0.0 = instant snap, 1.0 = never moves (use values like 0.1 – 0.3).
@export_range(0.0, 1.0, 0.01) var rotation_smoothing: float = 0.15

@export_group("Audio Sensitivity")
## Audio level (0.0 – 1.0) that must be exceeded before rotation begins.
## Raise this if the pipe rotates too easily from background noise.
@export_range(0.0, 1.0, 0.01) var active_threshold: float = 0.1

## How many seconds after audio drops below the threshold before the pipe
## returns to its resting angle. Prevents jittery snapping back.
@export_range(0.0, 2.0, 0.05) var return_delay: float = 0.3

@export_group("Polling")
## How often (in seconds) the audio level is sampled.
## Lower values are more responsive; higher values are less CPU-intensive.
@export_range(0.01, 0.5, 0.01) var poll_interval: float = 0.05

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

## The rotation angle (degrees) we are currently interpolating toward.
var _target_rotation_deg: float = 0.0

## Countdown until the pipe returns to its resting angle after audio drops.
## While > 0.0 the last driven angle is kept; ticked down every frame.
var _return_countdown: float = 0.0

## Timer used for polling the AudioManager.
var _poll_timer: Timer

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_setup_poll_timer()
	# Initialise target to the resting angle
	_target_rotation_deg = rotation_min_deg
	if rotate_target:
		rotate_target.rotation_degrees = rotation_min_deg

func _process(delta: float) -> void:
	# Tick down the return countdown
	if _return_countdown > 0.0:
		_return_countdown -= delta
		if _return_countdown <= 0.0:
			_return_countdown = 0.0
			_target_rotation_deg = rotation_min_deg

	# Smoothly interpolate the target node's rotation toward the target
	if rotate_target:
		rotate_target.rotation_degrees = lerp(
			rotate_target.rotation_degrees,
			_target_rotation_deg,
			1.0 - rotation_smoothing
		)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Creates and starts the timer that periodically samples audio input.
func _setup_poll_timer() -> void:
	_poll_timer = Timer.new()
	_poll_timer.name = "RotatePollTimer"
	_poll_timer.autostart = true
	_poll_timer.wait_time = poll_interval
	_poll_timer.one_shot = false
	_poll_timer.timeout.connect(_on_poll)
	add_child(_poll_timer)

# ---------------------------------------------------------------------------
# Audio polling
# ---------------------------------------------------------------------------

func _on_poll() -> void:
	var volume: float = AudioManager.get_audio_input()
	var is_active: bool = volume >= active_threshold

	if is_active:
		# Cancel any pending return countdown
		_return_countdown = 0.0
		# Map volume from [active_threshold, 1.0] → [rotation_min_deg, rotation_max_deg]
		_target_rotation_deg = _volume_to_rotation(volume)
	else:
		# Start the return countdown only if not already counting down
		if _return_countdown == 0.0:
			_return_countdown = return_delay

## Maps the audio volume to a rotation angle in degrees.
## Volume is remapped from [active_threshold, 1.0] → [rotation_min_deg, rotation_max_deg].
func _volume_to_rotation(volume: float) -> float:
	var t: float = clamp(
		(volume - active_threshold) / (1.0 - active_threshold),
		0.0, 1.0
	)
	return lerp(rotation_min_deg, rotation_max_deg, t)
