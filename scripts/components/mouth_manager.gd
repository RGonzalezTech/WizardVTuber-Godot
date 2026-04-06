class_name MouthManager
extends Node2D

## This node is responsible for showing either an open mouth or a closed mouth
## based on the current audio input level reported by AudioManager.

@export_group("Mouth")
## The mouth sprite/node to show when speaking (audio above threshold)
@export var mouth_open: Node2D
## The mouth sprite/node to show when silent (audio below threshold)
@export var mouth_closed: Node2D

@export_group("Mouth Open Scale")
## X scale of mouth_open at minimum volume (open_threshold). Higher = wider.
@export_range(0.1, 3.0, 0.01) var mouth_open_scale_x_min: float = 1.3
## X scale of mouth_open at maximum volume (1.0). Lower = narrower.
@export_range(0.1, 3.0, 0.01) var mouth_open_scale_x_max: float = 0.7
## Y scale of mouth_open at minimum volume (open_threshold). Lower = flatter.
@export_range(0.1, 3.0, 0.01) var mouth_open_scale_y_min: float = 0.3
## Y scale of mouth_open at maximum volume (1.0). Higher = taller.
@export_range(0.1, 3.0, 0.01) var mouth_open_scale_y_max: float = 1.2

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
			_update_mouth_open_scale(volume)
	else:
		# Reset the open-hold accumulator
		_active_time = 0.0

		# Start the close countdown only if the mouth is open and not already counting
		var just_stopped_talking = _mouth_open and _stop_talking_countdown == 0.0
		if just_stopped_talking:
			# if the mouth is still open, then we will start counting down
			# to close the mouth (occurs in _process)
			_stop_talking_countdown = close_delay

## Scales the mouth_open sprite based on the current volume level.
## volume is mapped from [open_threshold, 1.0] → [min_scale, max_scale] on each axis.
func _update_mouth_open_scale(volume: float) -> void:
	var t: float = clamp(
		(volume - open_threshold) / (1.0 - open_threshold),
		0.0, 1.0
	)
	var scale_x: float = lerp(mouth_open_scale_x_min, mouth_open_scale_x_max, t)
	var scale_y: float = lerp(mouth_open_scale_y_min, mouth_open_scale_y_max, t)
	mouth_open.scale = Vector2(scale_x, scale_y)

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
