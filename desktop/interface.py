#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#    "PyQt6",
#    "python-osc",
# ]
# ///
from pythonosc import udp_client
from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QPushButton,
    QGridLayout,
    QVBoxLayout,
    QSlider,
    QLabel,
)
from PyQt6.QtCore import Qt
import sys

all_buttons = [False] * 32
all_knobs = [0.0] * 5
client = udp_client.SimpleUDPClient("127.0.0.1", 8765)


class ToggleGrid(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Toggle Grid with Knobs")

        # Main layout (Vertical)
        self.main_layout = QVBoxLayout()
        self.setLayout(self.main_layout)

        # Knob (Slider) Layout
        self.knob_layout = QGridLayout()
        self.main_layout.addLayout(self.knob_layout)

        self.knobs = []
        for i in range(5):
            label = QLabel(f"Knob {i+1}: 0.0")
            slider = QSlider(Qt.Orientation.Horizontal)
            slider.setMinimum(0)
            slider.setMaximum(100)  # Scale it to allow fine adjustments
            slider.setValue(0)
            slider.setSingleStep(1)
            slider.valueChanged.connect(
                lambda value, lbl=label, i=i: self.knob_changed(value, lbl, i)
            )
            self.knob_layout.addWidget(label, 0, i)
            self.knob_layout.addWidget(slider, 1, i)
            self.knobs.append((slider, label))

        # Toggle Button Grid Layout
        self.grid_layout = QGridLayout()
        self.main_layout.addLayout(self.grid_layout)

        self.rows, self.cols = 4, 8
        self.buttons = {}

        for x in range(self.rows):
            for y in range(self.cols):
                btn = QPushButton("off")
                btn.setCheckable(True)
                btn.clicked.connect(lambda checked, x=x, y=y: self.toggle_button(x, y))
                self.grid_layout.addWidget(btn, x, y)
                self.buttons[(x, y)] = btn

    def toggle_button(self, x, y):
        button = self.buttons[(x, y)]
        new_state = "on" if button.text() == "off" else "off"
        button.setText(new_state)
        all_buttons[x * self.cols + y] = new_state == "on"
        client.send_message("/data", all_buttons + all_knobs)

    def knob_changed(self, value, label, index):
        float_value = round(value / 100, 2)  # Convert to 0.0 - 1.0 range
        label.setText(f"Knob {index+1}: {float_value}")
        all_knobs[index] = float_value
        client.send_message("/data", all_buttons + all_knobs)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = ToggleGrid()
    window.show()
    sys.exit(app.exec())
