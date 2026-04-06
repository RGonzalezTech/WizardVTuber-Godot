class_name BlinkManager
extends Node2D

## This node is responsible for showing a pair of eyes who will toggle
## visibility to simulate blinking.

@export_group("Eyes")
## The eyes to show when open
@export var eyes_open: Node2D
## The eyes to show when closed
@export var eyes_closed: Node2D

@export_group("Blinking")
## How long between blinks
@export_range(0.0, 20.0, 0.1) var minimum_blink_wait: float = 2.0
## Random offset to add to the blink timer (less predictable blinking)
@export_range(0.0, 5.0, 0.1) var blink_random_offset: float = 10.0

## How long the eyes are closed
@export_range(0.0, 1.618, 0.01) var blink_length: float = 0.15

# Start with the eyes open
var _eyes_open: bool = true

# The timer that controls blinking
var _blink_timer: Timer

func _ready() -> void:
    _setup_blink_timer()
    _render_eyes()

    _blink_timer.start(_get_next_blink_interval())

## Creates the timer and connects to its signal
func _setup_blink_timer() -> void:
    _blink_timer = Timer.new()
    _blink_timer.autostart = false
    _blink_timer.wait_time = minimum_blink_wait
    _blink_timer.one_shot = true
    _blink_timer.timeout.connect(_on_blink)
    add_child(_blink_timer)

func _on_blink() -> void:
    # Close the eyes
    _eyes_open = false
    _render_eyes()

    # Wait to open them
    await get_tree().create_timer(blink_length).timeout

    # Open the eyes
    _eyes_open = true
    _render_eyes()

    # Restart the timer with a randomized interval
    _blink_timer.start(_get_next_blink_interval())

func _get_next_blink_interval() -> float:
    return minimum_blink_wait + randf_range(0.0, blink_random_offset)

# If the eyes are open, show them
# Else, show the closed ones
func _render_eyes() -> void:
    if _eyes_open:
        eyes_open.show()
        eyes_closed.hide()
    else:
        eyes_open.hide()
        eyes_closed.show()
