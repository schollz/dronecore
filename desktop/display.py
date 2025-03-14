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
import sys
import threading
from PyQt6.QtWidgets import QApplication, QWidget, QHBoxLayout
from PyQt6.QtGui import QPainter, QPolygonF, QBrush, QColor
from PyQt6.QtCore import Qt, QPointF, QTimer

# add ../utils/displayutils.py to sys.path
sys.path.append("../utils")
sys.path.append("utils")
from displayutils import CHAR_MAP

SEGMENTS = {
    "A": [(20, 10), (80, 10), (70, 20), (30, 20)],
    "B": [(80, 10), (90, 20), (90, 70), (80, 80)],
    "C": [(80, 80), (90, 90), (90, 150), (80, 140)],
    "D": [(20, 150), (80, 150), (70, 140), (30, 140)],
    "E": [(10, 90), (20, 80), (20, 140), (10, 150)],
    "F": [(10, 20), (20, 10), (20, 70), (10, 80)],
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

#   ---A---
#  |       |
#  F       B
#  |       |
#   ---G---
#  |       |
#  E       C
#  |       |
#   ---D---
#
# 0bABCDEFG0

current_characters = [0] * 8
target_characters = [0] * 8


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
                    else QColor("#20000000")
                )
            )
            polygon = QPolygonF([QPointF(x, y) for x, y in points])
            painter.drawPolygon(polygon)


class DisplayEmulator(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("7-Segment Display Emulator")
        layout = QHBoxLayout()
        self.displays = [SevenSegmentDisplay() for _ in range(8)]
        for display in self.displays:
            layout.addWidget(display)
        self.setLayout(layout)

    def set_char(self, index, value):
        if 0 <= index < len(self.displays):
            self.displays[index].set_value(value)


def update_characters():
    for i in range(8):
        if current_characters[i] != target_characters[i]:
            diff = current_characters[i] ^ target_characters[i]
            differing_bits = [bit for bit in BIT_TO_SEGMENT if diff & bit]
            if differing_bits:
                bit_to_change = random.choice(
                    differing_bits
                )  # Choose a random bit to toggle
                current_characters[i] ^= bit_to_change  # Toggle that bit
                emulator.set_char(i, current_characters[i])
    app.processEvents()


def show_bar(value):
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

    for i in range(num_full_digits):
        target_characters[i] = segment_patterns[-1]

    if fractional_index:
        target_characters[num_full_digits] = segment_patterns[fractional_index]


def show_message(msg):
    msg = msg.upper()
    for i in range(8):
        if i < len(msg):
            target_characters[i] = CHAR_MAP.get(msg[i], 0)
        else:
            target_characters[i] = 0
        time.sleep(0.2)


def test_basic():
    def run():
        show_bar(0.5)
        time.sleep(0.5)
        show_bar(0.25)
        time.sleep(0.1)
        show_bar(0.75)
        time.sleep(2)

        show_message("HELLO")
        time.sleep(2)

        show_message("WORLD")
        time.sleep(2)
        show_message("WOTLD")
        time.sleep(0.2)
        show_message("WORLD")
        time.sleep(2)

    threading.Thread(target=run, daemon=True).start()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    emulator = DisplayEmulator()
    emulator.show()

    current_characters = [0] * 8
    target_characters = [0] * 8

    timer = QTimer()
    timer.timeout.connect(update_characters)
    timer.start(100)  # Update every 50 milliseconds

    test_basic()
    sys.exit(app.exec())
