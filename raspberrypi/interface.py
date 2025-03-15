import smbus2
import time
from pythonosc import udp_client
import RPi.GPIO as GPIO


all_buttons = [False] * 32
all_knobs = [0.0] * 5
client = udp_client.SimpleUDPClient("127.0.0.1", 57121)


class MultiplexedDigitalReader:
    """
    Class to interface with a multiplexer using GPIO for digital reading.
    """

    def __init__(
        self, select_pins=(4, 17, 27), input_pin=26, osc_ip="127.0.0.1", osc_port=8000
    ):
        """
        Initialize GPIO pins for multiplexing and OSC communication.

        :param select_pins: Tuple of three GPIO pins for channel selection.
        :param input_pin: GPIO pin for reading the digital value.
        :param osc_ip: IP address for sending OSC messages.
        :param osc_port: Port for sending OSC messages.
        """
        if len(select_pins) != 3:
            raise ValueError("select_pins must contain exactly 3 GPIO pins")
        self.select_pins = select_pins
        self.input_pin = input_pin
        self.last_values = {ch: None for ch in range(8)}  # Store last known states

        # Setup GPIO
        GPIO.setmode(GPIO.BCM)
        for pin in self.select_pins:
            GPIO.setup(pin, GPIO.OUT)  # Multiplexer control
        GPIO.setup(self.input_pin, GPIO.IN)  # Digital input

    def set_multiplexer_channel(self, channel):
        """
        Set the multiplexer to the desired channel using the select pins.
        :param channel: Channel number (0-7).
        """
        # Convert channel number to 3-bit binary and set GPIOs accordingly
        for i, pin in enumerate(self.select_pins):
            bit_value = (channel >> i) & 1
            GPIO.output(pin, bit_value)

    def read_channel(self, channel):
        """
        Read the digital value from the selected channel.
        :param channel: Channel number (0-7).
        :return: Digital readout (0 or 1).
        """
        self.set_multiplexer_channel(channel)
        time.sleep(0.001)  # Small delay for stabilization
        return 1 - GPIO.input(self.input_pin)

    def read_all_channels(self):
        """
        Reads all 8 channels and sends OSC messages if a change occurs.
        """
        any_value_changed = False
        for ch in range(8):
            new_value = self.read_channel(ch)
            last_value = self.last_values[ch]

            if last_value is None or new_value != last_value:
                any_value_changed = True

            self.last_values[ch] = new_value
            time.sleep(0.01)
        return any_value_changed

    def get_values(self):
        """
        Returns the current state of all 8 channels.
        :return: List of 8 boolean values.
        """
        return [self.last_values[ch] for ch in range(8)]

    def cleanup(self):
        """Cleans up GPIO settings."""
        GPIO.cleanup()


class ADS7830:
    """Class to interface with the ADS7830 ADC over I2C and send OSC messages on significant value change."""

    # ADS7830 command bytes for each channel
    COMMANDS = {
        0: 0b10000100,
        1: 0b11000100,
        2: 0b10010100,
        3: 0b11010100,
        4: 0b10100100,
        5: 0b11100100,
        6: 0b10110100,
        7: 0b11110100,
    }

    def __init__(self, i2c_address=0x48, i2c_bus=1):
        """Initialize ADS7830 with I2C address and bus number, and configure OSC client."""
        self.i2c_address = i2c_address
        self.bus = smbus2.SMBus(i2c_bus)
        self.last_values = {ch: None for ch in range(8)}  # Store last values

    def read_channel(self, channel):
        """
        Reads the ADC value from a specified channel (0-7).
        Returns the raw 8-bit ADC value (0-255).
        """
        if channel not in self.COMMANDS:
            raise ValueError("Channel must be between 0 and 7")

        command_byte = self.COMMANDS[channel]

        try:
            # Send command byte
            self.bus.write_byte(self.i2c_address, command_byte)
            time.sleep(0.001)  # Small delay to allow ADC conversion

            # Read single byte ADC result
            adc_value = self.bus.read_byte(self.i2c_address)
            return adc_value
        except Exception as e:
            print(f"Error reading channel {channel}: {e}")
            return None

    def read_all_channels(self):
        """Reads all 8 channels, detects significant changes, and sends OSC messages."""
        any_value_changed = False
        for ch in range(8):
            new_value = self.read_channel(ch)

            if new_value is not None:
                last_value = self.last_values[ch]

                # If the change is greater than 1, send an OSC message
                if last_value is None or abs(new_value - last_value) > 1:
                    normalized_value = (new_value - 24) / (255.0 - 24)
                    if normalized_value < 0:
                        normalized_value = 0
                    if normalized_value > 1:
                        normalized_value = 1
                    any_value_changed = True
                # Update stored value
                self.last_values[ch] = new_value

            time.sleep(0.01)  # Small delay between readings
        return any_value_changed

    def get_values(self):
        """
        Returns the current state of all 8 channels.
        :return: List of 5 integer values.
        """
        return [self.last_values[ch] for ch in range(5)]


if __name__ == "__main__":
    adc = ADS7830(i2c_address=0x48)
    reader = MultiplexedDigitalReader(select_pins=(17, 26, 27), input_pin=4)
    while True:
        changed = reader.read_all_channels()
        changed = changed or adc.read_all_channels()
        if changed:
            client.send_message("/data", reader.get_values() + adc.get_values())
        time.sleep(0.01)  # Loop delay
