class_name MouseMoveManager
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

func _ready() -> void:
    CompanionListener.mouse_moved.connect(_on_mouse_moved)

func _on_mouse_moved(mouse_x: float, mouse_y: float) -> void:
    var top_left_x = lerpf(top_left.x, top_right.x, mouse_x)
    var top_left_y = lerpf(top_left.y, top_right.y, mouse_x)
    var bottom_left_x = lerpf(bottom_left.x, bottom_right.x, mouse_x)
    var bottom_left_y = lerpf(bottom_left.y, bottom_right.y, mouse_x)

    var top_left_vec = Vector2(top_left_x, top_left_y)
    var bottom_left_vec = Vector2(bottom_left_x, bottom_left_y)
    position = lerp(top_left_vec, bottom_left_vec, mouse_y)
