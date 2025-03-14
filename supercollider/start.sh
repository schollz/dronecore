#!/bin/bash

# Get current directory
sleep 3
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Linking $DIR/InstrumentSample2.sc to $HOME/.local/share/SuperCollider/Extensions/InstrumentSample2.sc"
rm -rf $HOME/.local/share/SuperCollider/Extensions/InstrumentSample2.sc
ln -snf $DIR/InstrumentSample2.sc $HOME/.local/share/SuperCollider/Extensions/InstrumentSample2.sc
