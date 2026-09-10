class_name CursorTracker
extends Node2D

## Makes the node move around in relation to the mouse position.

## The position when the mouse is in the top-left corner
@export var top_left: Vector2
## The position when the mouse is in the top-right corner
@export var top_right: Vector2
## The position when the mouse is in the bottom-left corner
@export var bottom_left: Vector2
## The position when the mouse is in the bottom-right corner
@export var bottom_right: Vector2
## How fast the node catches up to the target (higher = snappier)
@export var lerp_speed: float = 15.0

var _target: Vector2

func _ready() -> void:
    _target = position
    CompanionListener.mouse_moved.connect(_on_mouse_moved)

func _process(delta: float) -> void:
    position = position.lerp(_target, clamp(lerp_speed * delta, 0.0, 1.0))

func _on_mouse_moved(mouse_x: float, mouse_y: float) -> void:
    var top_x = lerpf(top_left.x, top_right.x, mouse_x)
    var top_y = lerpf(top_left.y, top_right.y, mouse_y)
    var bot_x = lerpf(bottom_left.x, bottom_right.x, mouse_x)
    var bot_y = lerpf(bottom_left.y, bottom_right.y, mouse_y)

    _target.x = lerpf(top_x, bot_x, mouse_y)
    _target.y = lerpf(top_y, bot_y, mouse_y)
