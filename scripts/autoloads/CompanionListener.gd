class_name CompanionListenerCode
extends Node

#region Constants
const DEFAULT_PORT := 9876
const DEFAULT_ADDRESS := "127.0.0.1"
#endregion

#region Signals
## Emitted every time a packet is received and parsed
signal activity_updated(data: Dictionary)

## Emitted when mouse position changes
signal mouse_moved(mouse_x: float, mouse_y: float)

## Emitted when typing state toggles
signal typing_changed(is_typing: bool)
#endregion

#region Public State
## Normalized mouse X (0.0 = left edge, 1.0 = right edge)
var mouse_x: float = 0.5

## Normalized mouse Y (0.0 = top edge, 1.0 = bottom edge)
var mouse_y: float = 0.5

## Whether the user is actively typing (key pressed within the last ~1s)
var is_typing: bool = false

## True when the UDP server is bound and listening
var is_listening: bool = false
#endregion

#region Private
var _server: PacketPeerUDP
var _port: int = DEFAULT_PORT
var _address: String = DEFAULT_ADDRESS
#endregion

#region API
## Start the UDP server on the given port
func start_listening(port: int = DEFAULT_PORT, address: String = DEFAULT_ADDRESS) -> bool:
	if _server != null and _server.is_bound():
		stop_listening()

	_port = port
	_address = address
	_server = PacketPeerUDP.new()
	var err = _server.bind(_port, _address)
	if err != OK:
		push_error("[CompanionListener] Failed to bind UDP on %s:%d (error %d)" % [_address, _port, err])
		_server = null
		is_listening = false
		return false

	is_listening = true
	print("[CompanionListener] Listening on %s:%d" % [_address, _port])
	return true

## Stop the UDP server
func stop_listening() -> void:
	if _server != null:
		_server.close()
		_server = null
	is_listening = false
#endregion

#region Lifecycle
func _enter_tree() -> void:
	start_listening()

func _exit_tree() -> void:
	stop_listening()

func _process(_delta: float) -> void:
	if _server == null or not _server.is_bound():
		return

	# Poll for pending packets
	while _server.get_available_packet_count() > 0:
		var packet = _server.get_packet()
		if packet == null or packet.size() == 0:
			continue

		var text = packet.get_string_from_utf8()
		var json = JSON.new()
		var err = json.parse(text)
		if err != OK:
			push_warning("[CompanionListener] Invalid JSON packet: %s" % text)
			continue

		var data: Dictionary = json.get_data()
		if data == null:
			continue

		_apply_packet(data)
#endregion

#region Internal
func _apply_packet(data: Dictionary) -> void:
	var changed := false

	if data.has("mouse_x") and data.has("mouse_y"):
		var new_x: float = data["mouse_x"]
		var new_y: float = data["mouse_y"]
		if new_x != mouse_x or new_y != mouse_y:
			mouse_x = new_x
			mouse_y = new_y
			mouse_moved.emit(mouse_x, mouse_y)
			changed = true

	if data.has("is_typing"):
		var typing: bool = data["is_typing"]
		if typing != is_typing:
			is_typing = typing
			typing_changed.emit(is_typing)
			changed = true

	if changed:
		activity_updated.emit(data)
#endregion