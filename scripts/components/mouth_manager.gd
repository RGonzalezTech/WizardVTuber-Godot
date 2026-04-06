class_name MouthManager
extends Node2D

## This node is responsible for showing either an open mouth or a closed mouth
## based on the current audio input level reported by AudioManager.

@export_group("Mouth")
## The mouth sprite/node to show when speaking (audio above threshold)
@export var mouth_open: Node2D
## The mouth sprite/node to show when silent (audio below threshold)
@export var mouth_closed: Node2D

@export_group("Audio Sensitivity")
## Audio level (0.0 – 1.0) that must be exceeded for the mouth to open.
## Raise this if the mouth opens too easily; lower it if it feels sluggish.
@export_range(0.0, 1.0, 0.01) var open_threshold: float = 0.3

## How many consecutive seconds above the threshold are required before
## the mouth actually opens. Prevents single-frame blips from opening the mouth.
@export_range(0.0, 0.5, 0.01) var open_hold_time: float = 0.0

## How many seconds the mouth stays open after audio drops back below the
## threshold. This avoids an overly choppy, flickery appearance.
@export_range(0.0, 2.0, 0.05) var close_delay: float = 0.2

@export_group("Polling")
## How often (in seconds) the audio level is sampled.
## Lower values are more responsive; higher values are less CPU-intensive.
@export_range(0.01, 0.5, 0.01) var poll_interval: float = 0.05

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

## Whether the mouth is currently rendered as open
var _mouth_open: bool = false

## Accumulated time the audio has been continuously above the threshold
var _active_time: float = 0.0

## Countdown until the mouth closes after audio drops below the threshold.
## While > 0.0 the mouth stays open; ticked down every frame in _process.
var _stop_talking_countdown: float = 0.0

## Timer used for polling the AudioManager
var _poll_timer: Timer

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_setup_poll_timer()
	_render_mouth()

func _process(delta: float) -> void:
	if _stop_talking_countdown > 0.0:
		_stop_talking_countdown -= delta
		if _stop_talking_countdown <= 0.0:
			_stop_talking_countdown = 0.0
			_set_mouth_open(false)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Creates and starts the timer that periodically samples audio input
func _setup_poll_timer() -> void:
	_poll_timer = Timer.new()
	_poll_timer.name = "MouthPollTimer"
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
	var is_speaking = volume >= open_threshold

	if is_speaking:
		# Accumulate time spent above threshold
		_active_time += poll_interval

		# Still speaking — cancel any pending close countdown
		_stop_talking_countdown = 0.0

		# Open the mouth once the hold requirement is met
		if _active_time >= open_hold_time:
			_set_mouth_open(true)
	else:
		# Reset the open-hold accumulator
		_active_time = 0.0

		# Start the close countdown only if the mouth is open and not already counting
		var just_stopped_talking = _mouth_open and _stop_talking_countdown == 0.0
		if just_stopped_talking:
			# if the mouth is still open, then we will start counting down
			# to close the mouth (occurs in _process)
			_stop_talking_countdown = close_delay

# ---------------------------------------------------------------------------
# State helpers
# ---------------------------------------------------------------------------

## Updates internal state and re-renders only when the state actually changes
func _set_mouth_open(open: bool) -> void:
	if _mouth_open == open:
		return
	_mouth_open = open
	_render_mouth()

## Shows the correct mouth node based on the current state
func _render_mouth() -> void:
	if _mouth_open:
		mouth_open.show()
		mouth_closed.hide()
	else:
		mouth_open.hide()
		mouth_closed.show()
