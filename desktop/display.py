#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#    "PyQt6",
#    "python-osc",
# ]
# ///
import sys
import random
import time
import threading
import asyncio
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout
from PyQt6.QtGui import QPainter, QPolygonF, QBrush, QColor
from PyQt6.QtCore import Qt, QPointF, QTimer
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import AsyncIOOSCUDPServer

sys.path.append("../utils")
sys.path.append("utils")
from displayutils import CHAR_MAP

SEGMENTS = {
    "A": [(20, 10), (80, 10), (70, 20), (30, 20)],
    "B": [(80, 10), (90, 20), (90, 70), (80, 80)],
    "C": [(80, 80), (90, 90), (90, 140), (80, 150)],
    "D": [(20, 150), (80, 150), (70, 140), (30, 140)],
    "E": [(20, 80), (10, 90), (10, 140), (20, 150)],
    "F": [(20, 10), (10, 20), (10, 70), (20, 80)],
    "G": [(20, 80), (80, 80), (70, 90), (30, 90)],
}

BIT_TO_SEGMENT = {
    0b10000000: "A",
    0b01000000: "B",
    0b00100000: "C",
    0b00010000: "D",
    0b00001000: "E",
    0b00000100: "F",
    0b00000010: "G",
    0b00000001: "DP",
}

current_characters = [[0] * 8 for _ in range(2)]
target_characters = [[0] * 8 for _ in range(2)]


class SevenSegmentDisplay(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.segments_on = set()
        self.setFixedSize(100, 160)

    def set_value(self, value):
        self.segments_on = {
            BIT_TO_SEGMENT[bit] for bit in BIT_TO_SEGMENT if value & bit
        }
        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        for segment, points in SEGMENTS.items():
            painter.setBrush(
                QBrush(
                    QColor("#EE0000")
                    if segment in self.segments_on
                    else QColor("#00000000")
                )
            )
            polygon = QPolygonF([QPointF(x, y) for x, y in points])
            painter.drawPolygon(polygon)


class DisplayEmulator(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("7-Segment Display Emulator")
        self.setStyleSheet("background-color: white;")
        layout = QVBoxLayout()
        self.displays = [[SevenSegmentDisplay() for _ in range(8)] for _ in range(2)]
        for row in self.displays:
            row_layout = QHBoxLayout()
            for display in row:
                row_layout.addWidget(display)
            layout.addLayout(row_layout)
        self.setLayout(layout)

    def set_char(self, display_index, char_index, value):
        if 0 <= display_index < len(self.displays) and 0 <= char_index < len(
            self.displays[display_index]
        ):
            self.displays[display_index][char_index].set_value(value)


def update_characters():
    for display_index in range(2):
        for i in range(8):
            if (
                current_characters[display_index][i]
                != target_characters[display_index][i]
            ):
                diff = (
                    current_characters[display_index][i]
                    ^ target_characters[display_index][i]
                )
                differing_bits = [bit for bit in BIT_TO_SEGMENT if diff & bit]
                if differing_bits:
                    bit_to_change = random.choice(differing_bits)
                    current_characters[display_index][i] ^= bit_to_change
                    emulator.set_char(
                        display_index, i, current_characters[display_index][i]
                    )
    app.processEvents()


def show_bar(display_index, value):
    if not 0.0 <= value <= 1.0:
        raise ValueError("Value must be between 0.0 and 1.0")

    num_full_digits = int(value * 8)
    fractional_part = (value * 8) - num_full_digits

    segment_patterns = [
        0x00,
        0b00000100,
        0b00001100,
        0b00001110,
        0b10001110,
        0b10011110,
        0b11011110,
        0b11111110,
    ]
    fractional_index = int(fractional_part * (len(segment_patterns) - 1))

    for i in range(8):
        if i < num_full_digits:
            target_characters[display_index][i] = segment_patterns[-1]
        elif i == num_full_digits:
            target_characters[display_index][i] = segment_patterns[fractional_index]
        else:
            target_characters[display_index][i] = 0


def show_message(display_index, msg):
    msg = msg.upper()
    print(f"Displaying message: {msg} on display {display_index}")
    for i in range(8):
        if i < len(msg):
            target_characters[display_index][i] = CHAR_MAP.get(msg[i], 0)
        else:
            target_characters[display_index][i] = 0
        time.sleep(0.005)


async def osc_handler(address, *args):
    print(f"Received OSC message: {address}")
    if address == "/display":
        index = int(args[0])
        if args[1] == "bar":
            show_bar(index, float(args[2]))
        elif args[1] == "msg":
            show_message(index, args[2])


def osc_callback(address, *args):
    asyncio.create_task(osc_handler(address, *args))


async def init_main():
    dispatcher = Dispatcher()
    dispatcher.map("/display", osc_callback)
    server = AsyncIOOSCUDPServer(
        ("0.0.0.0", 57122), dispatcher, asyncio.get_running_loop()
    )
    transport, protocol = await server.create_serve_endpoint()
    try:
        await asyncio.Future()
    finally:
        transport.close()


def run_asyncio_loop():
    asyncio.set_event_loop(asyncio.new_event_loop())
    loop = asyncio.get_event_loop()
    loop.run_until_complete(init_main())


if __name__ == "__main__":
    asyncio_thread = threading.Thread(target=run_asyncio_loop, daemon=True)
    asyncio_thread.start()
    app = QApplication(sys.argv)
    emulator = DisplayEmulator()
    emulator.show()
    timer = QTimer()
    timer.timeout.connect(update_characters)
    timer.start(1)
    sys.exit(app.exec())
