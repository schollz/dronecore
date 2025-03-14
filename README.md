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
- raspberrypi/interface.py 
  - sends osc to the orchestrator.go
- desktop/interface.py
  - sends osc to the orchestrator.go
- orchestrator.go (osc 57121)
  - sends osc to sclang 
  - sends osc to desktop/display.py
  - sends osc to raspberrypi/display.py
- sclang (osc 57120) sends audio to jackd
- jackd sends audio to speakers
- desktop/display.py (osc 57122)
  - sends osc to desktop/7seg.py
- desktop/7seg.py (osc 57123)
  - display 7-segment display using PyQT
- raspberry/display.py (osc 57122)
  - sends spi commands to 7-segment display

```mermaid
graph TD;
    A[raspberrypi/interface.py] -->|OSC Event| C[orchestrator.go:57121]
    B[desktop/interface.py] -->|OSC Event| C
    C -->|OSC Message| D[sclang:57120]
    C -->|OSC Message| H[desktop/display.py:57122]
    C -->|OSC Message| K[raspberry/display.py:57122]
    
    D -->|Audio Signal| F[jackd]
    F -->|Audio Output| G[Speakers]
    
    H -->|OSC Message| I[desktop/7seg.py:57123]
    I -->|PyQT Render| J[7-Segment Display]
    
    K -->|SPI Command| L[Physical 7-Segment Display]
    
    subgraph Desktop
        B
        H
        I
        J
    end
    
    subgraph RaspberryPi
        A
        K
        L
    end
    
    subgraph Audio Processing
        D
        F
        G
    end

```