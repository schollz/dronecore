#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "luma.core==2.4.2",
#     "RPi.GPIO==0.7.1",
#     "luma.led-matrix==1.7.1",
# ]
# ///

import time
import spidev  # Use spidev for direct MAX7219 communication
import RPi.GPIO as GPIO

# Set up GPIO mode
GPIO.setmode(GPIO.BCM)

# SPI Configuration
SPI_BUS = 0
SPI_DEVICE = 0
spi = spidev.SpiDev()
spi.open(SPI_BUS, SPI_DEVICE)
spi.max_speed_hz = 1000000  # Set SPI speed to 1 MHz

# MAX7219 Register Addresses
DIGIT_REGS = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]  # Digits 1-8 per display
DECODE_MODE = 0x09
INTENSITY = 0x0A
SCAN_LIMIT = 0x0B
SHUTDOWN = 0x0C
DISPLAY_TEST = 0x0F

# Set number of daisy-chained displays
num_cascaded = 2  # Two MAX7219 displays

# Character map for 7-segment representation
CHAR_MAP = {
    "0": 0x7E, "1": 0x30, "2": 0x6D, "3": 0x79, "4": 0x33,
    "5": 0x5B, "6": 0x5F, "7": 0x70, "8": 0x7F, "9": 0x7B,
    "A": 0x77, "B": 0x1F, "C": 0x4E, "D": 0x3D, "E": 0x4F,
    "F": 0x47, "G": 0x5E, "H": 0x37, "I": 0x06, "J": 0x38,
    "L": 0x0E, "N": 0x15, "O": 0x7E, "P": 0x67, "R": 0x05,
    "S": 0x5B, "T": 0x0F, "U": 0x3E, "Y": 0x3B, "Z": 0x6D,
    "-": 0x01, " ": 0x00
}


def send_to_max7219(register, data, display_num):
    """Send a command to a specific MAX7219 display in the daisy-chain."""
    packet = [0x00] * (num_cascaded * 2)  # Create a blank command packet
    packet[display_num * 2] = register
    packet[display_num * 2 + 1] = data
    spi.xfer2(packet)  # Send SPI packet


def initialize_max7219():
    """Initialize all MAX7219 displays in the daisy-chain."""
    for display in range(num_cascaded):
        send_to_max7219(SHUTDOWN, 0x01, display)  # Enable display
        send_to_max7219(DISPLAY_TEST, 0x00, display)  # Disable test mode
        send_to_max7219(DECODE_MODE, 0x00, display)  # No BCD decoding for text
        send_to_max7219(INTENSITY, 0x01, display)  # Set brightness
        send_to_max7219(SCAN_LIMIT, 0x07, display)  # Show all 8 digits


def clear_displays():
    """Clears all digits on both displays."""
    for display in range(num_cascaded):
        for reg in DIGIT_REGS:
            send_to_max7219(reg, 0x00, display)  # Blank out all digits


def show_message(msg):
    """Display a static alphanumeric message across two MAX7219 displays."""
    msg = msg.upper()[::-1]  # Convert to uppercase and reverse for correct order
    
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


def main():
    """Main function to display a message across two daisy-chained MAX7219 displays."""
    print("Displaying static message at FULL brightness. Press CTRL+C to exit.")
    try:
        initialize_max7219()
        show_message("HELLO 42")  # Example alphanumeric message
        while True:
            time.sleep(1)  # Keep running
    except KeyboardInterrupt:
        print("Exiting program")
    finally:
        spi.close()
        GPIO.cleanup()


if __name__ == "__main__":
    main()

