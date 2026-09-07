class_name LookManager
extends Node2D

@export var top_left: Vector2
@export var bottom_right: Vector2
@export var lerp_speed: float = 15.0

var _target: Vector2

func _ready() -> void:
    assert(top_left != null, "Top Left not set")
    assert(bottom_right != null, "Bottom Right not set")
    _target = position
    CompanionListener.mouse_moved.connect(_on_mouse_moved)

func _process(delta: float) -> void:
    position = position.lerp(_target, clamp(lerp_speed * delta, 0.0, 1.0))

func _on_mouse_moved(mouse_x: float, mouse_y: float) -> void:
    _target.x = lerpf(top_left.x, bottom_right.x, mouse_x)
    _target.y = lerpf(top_left.y, bottom_right.y, mouse_y)
