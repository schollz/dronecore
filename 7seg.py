#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#    "PyQt6",
#    "python-osc",
# ]
# ///
import time
import sys
from PyQt6.QtWidgets import QApplication, QWidget, QHBoxLayout, QVBoxLayout, QLabel
from PyQt6.QtGui import QPainter, QPolygonF, QBrush, QColor
from PyQt6.QtCore import Qt, QPointF

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

CHAR_MAP = {
    "0": 0b11111100,
    "1": 0b01100000,
    "2": 0b11011010,
    "3": 0b11110010,
    "4": 0b01100110,
    "5": 0b10110110,
    "6": 0b10111110,
    "7": 0b11100000,
    "8": 0b11111110,
    "9": 0b11110110,
    "A": 0b11101110,
    "B": 0b00111110,
    "C": 0b10011100,
    "D": 0b01111010,
    "E": 0b10011110,
    "F": 0b10001110,
    "G": 0b10111100,
    "H": 0b01101110,
    "I": 0b01100000,
    "J": 0b01111000,
    "K": 0b01101110,
    "L": 0b00011100,
    "M": 0b00101010,
    "N": 0b00101010,
    "O": 0b11111100,
    "P": 0b11001110,
    "Q": 0b11100110,
    "R": 0b00001010,
    "S": 0b10110110,
    "T": 0b10001100,
    "U": 0b01111100,
    "V": 0b01111100,
    "W": 0b01111100,
    "X": 0b01101110,
    "Y": 0b01110110,
    "Z": 0b11011010,
    "-": 0b00000010,
    " ": 0b00000000,
}


def test_basic(app, emulator):
    for i in range(10):
        emulator.set_char(2, 1 << i)
        app.processEvents()
        time.sleep(0.05)
    s = "VERB"
    for i, c in enumerate(s):
        emulator.set_char(i, CHAR_MAP.get(c, 0))
    app.processEvents()
    time.sleep(2)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    emulator = DisplayEmulator()
    emulator.show()
    test_basic(app, emulator)
    sys.exit(app.exec())
