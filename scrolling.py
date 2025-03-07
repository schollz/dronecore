#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "luma.core",
#     "RPi.GPIO",
#     "luma.led_matrix",
# ]
# ///
#

import time
import RPi.GPIO as GPIO
from luma.led_matrix.device import max7219
from luma.core.interface.serial import spi, noop
from luma.core.render import canvas
from luma.core.virtual import viewport
from luma.core.legacy import text, show_message
from luma.core.legacy.font import proportional, CP437_FONT, TINY_FONT, SINCLAIR_FONT

GPIO.setmode(GPIO.BCM)

# GPIO Configuration
DIN_PIN = 10  # GPIO 10 (MOSI) - Connect to DIN pin on MAX7219
CS_PIN = 8  # GPIO 8 (CE0) - Connect to CS pin on MAX7219
CLK_PIN = 11  # GPIO 11 (SCLK) - Connect to CLK pin on MAX7219

# Create serial interface using SPI
serial = spi(
    port=0, device=0, gpio=GPIO, gpio_CS=CS_PIN, gpio_MOSI=DIN_PIN, gpio_SCLK=CLK_PIN
)

# Create device with 2 cascaded MAX7219 modules (two 8-digit displays)
num_cascaded = 2  # Modify based on how many MAX7219 modules you have connected
device = max7219(serial, cascaded=num_cascaded, blocks_arranged_in_reverse_order=False)

# Set brightness (0-255)
device.contrast(100)

# Define your scrolling message
message = "Hello Raspberry Pi with MAX7219 LED Display!"


def scroll_message():
    # Show scrolling message
    show_message(
        device, message, fill="white", font=proportional(CP437_FONT), scroll_delay=0.05
    )


def main():
    # Main loop
    print("Starting scrolling display. Press CTRL+C to exit.")
    try:
        while True:
            scroll_message()
            time.sleep(1)  # Pause between scrolls
    except KeyboardInterrupt:
        print("Exiting program")
    finally:
        # Clean up
        device.clear()
        GPIO.cleanup()


if __name__ == "__main__":
    main()
