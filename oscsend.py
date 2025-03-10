from pythonosc.udp_client import SimpleUDPClient


def send_osc_data(ip="127.0.0.1", port=57120, data=None):
    """
    Sends data to the OSC function '/data' in SuperCollider.

    :param ip: The IP address of the SuperCollider server (default is localhost).
    :param port: The port SuperCollider listens on (default is 57120).
    :param data: The data to send. Can be a single value or a list of values.
    """
    if data is None:
        data = []

    # Ensure data is a list for OSC transmission
    if not isinstance(data, list):
        data = [data]

    client = SimpleUDPClient(ip, port)  # Create the client
    client.send_message("/data", data)  # Send data to SuperCollider


# Example usage
send_osc_data(data=["piano", 1])
