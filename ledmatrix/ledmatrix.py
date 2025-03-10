#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "luma.core==2.4.2",
#     "RPi.GPIO==0.7.1",
#     "luma.led-matrix==1.7.1",
#     "python-osc==1.9.3",
# ]
# ///
import time
import threading
import spidev  # Use spidev for direct MAX7219 communication
import RPi.GPIO as GPIO
from pythonosc import dispatcher, osc_server

# Set up GPIO mode
GPIO.setmode(GPIO.BCM)

# SPI Configuration
SPI_BUS = 0
SPI_DEVICE = 0
spi = spidev.SpiDev()
spi.open(SPI_BUS, SPI_DEVICE)
spi.max_speed_hz = 1000000  # Set SPI speed to 1 MHz

# MAX7219 Register Addresses
DIGIT_REGS = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]
DECODE_MODE = 0x09
INTENSITY = 0x0A
SCAN_LIMIT = 0x0B
SHUTDOWN = 0x0C
DISPLAY_TEST = 0x0F

# Number of daisy-chained displays
num_cascaded = 2  # Two MAX7219 displays

# Character map for 7-segment representation
CHAR_MAP = {
    "0": 0x7E,
    "1": 0x30,
    "2": 0x6D,
    "3": 0x79,
    "4": 0x33,
    "5": 0x5B,
    "6": 0x5F,
    "7": 0x70,
    "8": 0x7F,
    "9": 0x7B,
    "A": 0x77,
    "B": 0x1F,
    "C": 0x4E,
    "D": 0x3D,
    "E": 0x4F,
    "F": 0x47,
    "G": 0x5E,
    "H": 0x37,
    "I": 0x06,
    "J": 0x38,
    "L": 0x0E,
    "N": 0x15,
    "O": 0x7E,
    "P": 0x67,
    "R": 0x05,
    "S": 0x5B,
    "T": 0x0F,
    "U": 0x3E,
    "V": 0x3E,
    "Y": 0x3B,
    "Z": 0x6D,
    "-": 0x01,
    " ": 0x00,
}


def send_to_max7219(register, data, display_num):
    packet = [0x00] * (num_cascaded * 2)
    packet[display_num * 2] = register
    packet[display_num * 2 + 1] = data
    spi.xfer2(packet)


def initialize_max7219():
    for display in range(num_cascaded):
        send_to_max7219(SHUTDOWN, 0x01, display)
        send_to_max7219(DISPLAY_TEST, 0x00, display)
        send_to_max7219(DECODE_MODE, 0x00, display)
        send_to_max7219(INTENSITY, 0x01, display)
        send_to_max7219(SCAN_LIMIT, 0x07, display)


def clear_displays():
    for display in range(num_cascaded):
        for reg in DIGIT_REGS:
            send_to_max7219(reg, 0x00, display)


def show_message(msg):
    msg = msg.upper()[::-1]
    clear_displays()
    digit_index = 0
    display_num = 0

    for char in msg:
        if char in CHAR_MAP:
            send_to_max7219(DIGIT_REGS[digit_index], CHAR_MAP[char], display_num)
            digit_index += 1
            if digit_index >= 8:
                display_num += 1
                digit_index = 0
                if display_num >= num_cascaded:
                    break


def show_bar(value, display_num=1):
    if not 0.0 <= value <= 1.0:
        raise ValueError("Value must be between 0.0 and 1.0")

    num_full_digits = int(value * 8)
    fractional_part = (value * 8) - num_full_digits


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

    segment_patterns = [
        0x00,
        0b0000010,
        0b0000110,
        0b0000111,
        0b1000111,
        0b1001111,
        0b1101111,
        0b1111111,
    ]
    fractional_index = int(fractional_part * (len(segment_patterns) - 1))

    for digit in range(8):
        if digit < num_full_digits:
            send_to_max7219(DIGIT_REGS[7 - digit], 0xFF, display_num)
        elif digit == num_full_digits and fractional_part > 0:
            send_to_max7219(
                DIGIT_REGS[7 - digit], segment_patterns[fractional_index], display_num
            )
        else:
            send_to_max7219(DIGIT_REGS[7 - digit], 0x00, display_num)


def osc_bar_handler(address, *args):
    value = float(args[0])
    print(f"Received bar update: {value}")
    show_bar(value)


def osc_message_handler(address, *args):
    message = str(args[0])
    print(f"Received message: {message}")
    show_message(message)


def start_osc_server():
    disp = dispatcher.Dispatcher()
    disp.map("/bar", osc_bar_handler)
    disp.map("/message", osc_message_handler)

    server = osc_server.ThreadingOSCUDPServer(("0.0.0.0", 8000), disp)
    print("OSC Server started on port 8000")
    server.serve_forever()


def main():
    initialize_max7219()
    clear_displays()

    osc_thread = threading.Thread(target=start_osc_server, daemon=True)
    osc_thread.start()

    try:
        while True:
            time.sleep(1)  # Keep the main thread alive
    except KeyboardInterrupt:
        print("Exiting...")
        spi.close()
        GPIO.cleanup()


if __name__ == "__main__":
    main()
