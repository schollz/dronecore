#!/bin/bash

# Find the card number for "HDA Intel PCH"
CARD_NUM=$(aplay -l | grep -m1 "DigiAMP" | awk '{print $2}' | sed 's/://')

# Run JACK with the detected card number
/usr/bin/jackd -d alsa -d hw:$CARD_NUM