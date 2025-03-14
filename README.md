# dronecore

## Pre-requisites

```
npm install -g pm2
```

## Start

```
pm2 flush
pm2 delete all
pm2 start ecosystem.config.js
```


```
jack -d alsa

air

./testui.py

sclang -D timeandspace.scd
```



Processes:
- gpio_listener.py 
  - sends osc events to the orchestrator.go
- interace_emulator.py
  - sends osc events to the orchestrator.go
- orchestrator.go (osc 57121)
  - sends osc events to sclang 
  - sends osc events to userinterface.py
- sclang (osc 57120) sends audio to jackd
- jackd sends audio to speakers
- 7seg_emulator.py (osc 57123) uses PyQT to display 7-segment display
- userinteface.py (osc 57122)
  - send messages to 7-segment display
  - sends messages to 7seg_emulator.py

```mermaid
graph TD;
    A[gpio_listener.py] -->|OSC Event| C[orchestrator.go:57121]
    B[interface_emulator.py] -->|OSC Event| C
    C -->|OSC Message| D[sclang:57120]
    C -->|OSC Message| E[userinterface.py:57122]
    D -->|Audio Signal| F[jackd]
    F -->|Audio Output| G[Speakers]
    E -->|OSC Message| H[7-Segment Display]
    E -->|OSC Message| I[7seg_emulator.py:57123]
    I -->|PyQT Render| J[7-Segment Emulator Display]

```