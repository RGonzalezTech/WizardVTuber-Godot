class_name AudioManagerCode
extends Node

#region Constants
## The default value for AudioServer.input_device
const DEFAULT_INPUT_DEVICE: StringName = "Default"

## The AudioBus created in Editor to capture microphone input
const CAPTURE_BUS: StringName = "CaptureAudio"
#endregion

#region Private Variables
## This player streams the microphone input
## to the Cpature audio bus (which is muted in-editor)
var _player: AudioStreamPlayer

## The index of the capture bus
var _capture_bus_index: int
#endregion

#region API
## Returns an array of microphone devices
func get_devices() -> PackedStringArray:
    return AudioServer.get_input_device_list()

## Sets the microphone device to listen to
func set_microphone_device(device: String) -> void:
    print("Setting Microphone Input: ", device)
    AudioServer.input_device = device

## Read the audio volume from the Capture Bus
## and report the "volume" heuristic between 0.0 and 1.0
func get_audio_input() -> float:
    var left_volume = AudioServer.get_bus_peak_volume_left_db(_capture_bus_index, 0)
    var right_volume = AudioServer.get_bus_peak_volume_right_db(_capture_bus_index, 0)
    var max_volume = max(left_volume, right_volume)
    return clamp(remap(max_volume, -60.0, 0.0, 0.0, 1.0), 0.0, 1.0)

#endregion

#region Init/Setup
func _enter_tree() -> void:
    _setup_stream_player()
    _capture_bus_index = AudioServer.get_bus_index(CAPTURE_BUS)
    assert(_capture_bus_index != -1, "Failed to find CaptureAudio bus")

func _setup_stream_player() -> void:
    _player = AudioStreamPlayer.new()
    _player.name = "MicrophoneStreamPlayer"
    _player.stream = AudioStreamMicrophone.new()
    # Route to Capture Bus (muted in editor)
    _player.bus = CAPTURE_BUS
    _player.autoplay = true

    # TODO: Use the config last used (store in config file)
    set_microphone_device(DEFAULT_INPUT_DEVICE)

    add_child(_player)
#endregion
