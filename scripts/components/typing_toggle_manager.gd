class_name ArmToggleManager
extends Node

## Toggles visibility between static and typing arm sprites based on
## [CompanionListener] typing events.

## Arm sprites shown when NOT typing (static pose)
@export var static_arms: Array[Node2D]

## Arm sprites shown when typing (animated pose)
@export var typing_arms: Array[Node2D]


func _ready() -> void:
	_apply_typing(CompanionListener.is_typing)
	CompanionListener.typing_changed.connect(_on_typing_changed)


func _on_typing_changed(is_typing: bool) -> void:
	_apply_typing(is_typing)


func _apply_typing(is_typing: bool) -> void:
	for arm in static_arms:
		arm.visible = not is_typing
	for arm in typing_arms:
		arm.visible = is_typing