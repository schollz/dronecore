#!/bin/bash

# Find the card number for "HDA Intel PCH"
CARD_NUM=$(aplay -l | grep -m1 "HDA Intel PCH" | awk '{print $2}' | sed 's/://')

# Default to card 0 if not found
if [ -z "$CARD_NUM" ]; then
    CARD_NUM=0
fi

# Run JACK with the detected card number
/usr/bin/jackd -d alsa -d hw:$CARD_NUM