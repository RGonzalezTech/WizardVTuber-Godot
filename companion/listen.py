#!/usr/bin/env python3
"""
Companion listener — monitors mouse position and typing activity, sends UDP packets
to the Godot WizardPipe CompanionListener autoload.

Runs on Windows (needs direct access to input devices — won't work under WSL).
"""

import json
import os
import socket
import sys
import threading
import time

UDP_IP = os.environ.get("COMPANION_UDP_IP", "127.0.0.1")
UDP_PORT = int(os.environ.get("COMPANION_UDP_PORT", "9876"))
UPDATE_HZ = int(os.environ.get("COMPANION_HZ", "30"))
TYPING_TIMEOUT = float(os.environ.get("COMPANION_TYPING_TIMEOUT", "1.0"))

# ---------------------------------------------------------------------------
# Platform check — this needs real Windows input APIs
# ---------------------------------------------------------------------------
if sys.platform != "win32":
    print(
        "companion/listen.py requires Windows (win32). "
        "It accesses Win32 input APIs directly and will not work under WSL. "
        "Run it from a Windows terminal: python companion\\listen.py"
    )
    sys.exit(1)

from ctypes import windll
from pynput import keyboard, mouse

# ---------------------------------------------------------------------------
# Global state
# ---------------------------------------------------------------------------
mouse_x: float = 0.5
mouse_y: float = 0.5
is_typing: bool = False
last_key_time: float = 0.0
_lock = threading.Lock()

# Virtual screen dimensions — the bounding rectangle of all monitors combined.
# pynput reports mouse coords in virtual-screen space, so we normalize against
# the full virtual desktop, not just the primary monitor.
SM_XVIRTUALSCREEN, SM_YVIRTUALSCREEN = 76, 77
SM_CXVIRTUALSCREEN, SM_CYVIRTUALSCREEN = 78, 79

VIRTUAL_LEFT: int = windll.user32.GetSystemMetrics(SM_XVIRTUALSCREEN)
VIRTUAL_TOP: int = windll.user32.GetSystemMetrics(SM_YVIRTUALSCREEN)
VIRTUAL_W: int = windll.user32.GetSystemMetrics(SM_CXVIRTUALSCREEN)
VIRTUAL_H: int = windll.user32.GetSystemMetrics(SM_CYVIRTUALSCREEN)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
shutdown_event = threading.Event()


# ---------------------------------------------------------------------------
# Input callbacks
# ---------------------------------------------------------------------------
def on_move(x: int, y: int) -> None:
    global mouse_x, mouse_y
    with _lock:
        mouse_x = (x - VIRTUAL_LEFT) / VIRTUAL_W
        mouse_y = (y - VIRTUAL_TOP) / VIRTUAL_H


def on_press(key) -> None:
    global is_typing, last_key_time
    with _lock:
        last_key_time = time.time()
        is_typing = True


def on_release(key) -> None:
    pass  # typing timeout handles the False transition


# ---------------------------------------------------------------------------
# Sender loop — runs in a background thread
# ---------------------------------------------------------------------------
def sender_loop() -> None:
    global is_typing
    interval = 1.0 / UPDATE_HZ

    while not shutdown_event.is_set():
        shutdown_event.wait(interval)
        if shutdown_event.is_set():
            break

        with _lock:
            # Decay typing flag after timeout
            if is_typing and (time.time() - last_key_time) > TYPING_TIMEOUT:
                is_typing = False

            packet = {
                "mouse_x": round(mouse_x, 4),
                "mouse_y": round(mouse_y, 4),
                "is_typing": is_typing,
            }

        data = json.dumps(packet).encode("utf-8")
        try:
            sock.sendto(data, (UDP_IP, UDP_PORT))
        except OSError:
            pass  # Godot not up yet — drop silently


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    print(f"Companion listener starting — UDP → {UDP_IP}:{UDP_PORT} @ {UPDATE_HZ} Hz")
    print(f"  Virtual desktop: left={VIRTUAL_LEFT}, top={VIRTUAL_TOP}, {VIRTUAL_W}x{VIRTUAL_H}")
    print(f"  Typing timeout: {TYPING_TIMEOUT}s")

    # Start pynput listeners
    mouse_listener = mouse.Listener(on_move=on_move)
    keyboard_listener = keyboard.Listener(on_press=on_press, on_release=on_release)
    mouse_listener.start()
    keyboard_listener.start()

    # Start sender thread
    sender = threading.Thread(target=sender_loop, daemon=True, name="companion-sender")
    sender.start()

    print("  Listening for input. Press Ctrl+C to stop.")

    try:
        # Keep the main thread alive to receive signals
        while not shutdown_event.is_set():
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nShutting down...")
    finally:
        shutdown_event.set()
        mouse_listener.stop()
        keyboard_listener.stop()
        sock.close()
        print("Companion listener stopped.")

if __name__ == "__main__":
    main()