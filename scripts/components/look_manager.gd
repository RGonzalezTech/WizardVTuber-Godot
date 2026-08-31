class_name LookManager
extends Node2D

@export var top_left: Vector2
@export var bottom_right: Vector2

func _ready() -> void:
    assert(top_left != null, "Top Left not set")
    assert(bottom_right != null, "Bottom Right not set")
    CompanionListener.mouse_moved.connect(_on_mouse_moved)

func _on_mouse_moved(mouse_x: float, mouse_y: float) -> void:
    var target_x = lerpf(top_left.x, bottom_right.x, mouse_x)
    var target_y = lerpf(top_left.y, bottom_right.y, mouse_y)
    position = Vector2(target_x, target_y)
