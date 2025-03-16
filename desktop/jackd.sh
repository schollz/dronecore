#!/bin/bash

CARD_NUM=$(aplay -l | grep -m1 "Scarlett 2i2 USB" | awk '{print $2}' | sed 's/://')

# Check if CARD_NUM is empty
if [ -z "$CARD_NUM" ]; then
    CARD_NUM=$(aplay -l | grep -m1 "HDA Intel PCH" | awk '{print $2}' | sed 's/://')
fi

# Default to card 0 if not found
if [ -z "$CARD_NUM" ]; then
    echo "No sound card found, exiting"
    exit 1
fi

# Run JACK with the detected card number
/usr/bin/jackd -d alsa -d hw:$CARD_NUM