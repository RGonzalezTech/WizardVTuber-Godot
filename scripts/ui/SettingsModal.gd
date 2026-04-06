class_name SettingsModalCode
extends PanelContainer

## Emitted when the user closes the modal
signal closed

@onready var _mic_option_button: OptionButton = %MicOptionButton
@onready var _close_button: Button = %CloseButton

func _ready() -> void:
	# Anchor presets from .tscn aren't recalculated on dynamic instantiation,
	# so we force the panel to center itself in its parent at runtime.
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_populate_microphone_list()
	_mic_option_button.item_selected.connect(_on_mic_selected)
	_close_button.pressed.connect(_on_close_pressed)

## Populate the OptionButton with available microphone devices
func _populate_microphone_list() -> void:
	_mic_option_button.clear()
	var devices := AudioManager.get_devices()
	var current_device := AudioServer.input_device

	for i in devices.size():
		_mic_option_button.add_item(devices[i], i)
		if devices[i] == current_device:
			_mic_option_button.select(i)

func _on_mic_selected(index: int) -> void:
	var device_name := _mic_option_button.get_item_text(index)
	AudioManager.set_microphone_device(device_name)

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
