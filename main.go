package main

import (
	"flag"
	"log/slog"
	"math"
	"math/rand"
	"os"
	"sync"
	"time"

	"github.com/hypebeast/go-osc/osc"
	"github.com/lmittmann/tint"
)

var oscClient *osc.Client

var mu sync.Mutex

func sendOSCMessage() {
	mu.Lock()
	defer mu.Unlock()
	msg := osc.NewMessage("/test")
	msg.Append(int32(1))
	msg.Append("Hello World")
	oscClient.Send(msg)
}

type SharedData struct {
	mu           sync.Mutex
	booleanArray [32]bool
	stopChan     chan struct{}
	updateChan   chan [32]bool
	logger       *slog.Logger
}

func NewSharedData(logger *slog.Logger) *SharedData {
	return &SharedData{
		booleanArray: [32]bool{},
		stopChan:     make(chan struct{}),
		updateChan:   make(chan [32]bool, 2),
		logger:       logger,
	}
}

func (sd *SharedData) Start() {
	go func() {
		for {
			select {
			case <-sd.stopChan:
				return
			case <-time.After(time.Duration(rand.Intn(5)+1) * time.Second):
				sd.mu.Lock()
				index := rand.Intn(len(sd.booleanArray))
				sd.booleanArray[index] = !sd.booleanArray[index]
				sd.logger.Info("Updated boolean array", slog.Int("index", index), slog.Bool("value", sd.booleanArray[index]))
				for range []int{0, 1} {
					select {
					case sd.updateChan <- sd.booleanArray:
					default:
					}
				}
				sd.mu.Unlock()
			}
		}
	}()
}

func (sd *SharedData) Stop() {
	close(sd.stopChan)
	close(sd.updateChan)
	sd.logger.Info("SharedData stopped")
}

type Metronome struct {
	sd       *SharedData
	bpm      float64
	stopChan chan struct{}
	logger   *slog.Logger
}

func NewMetronome(sd *SharedData, bpm float64, logger *slog.Logger) *Metronome {
	return &Metronome{
		sd:       sd,
		bpm:      bpm,
		stopChan: make(chan struct{}),
		logger:   logger,
	}
}

func (m *Metronome) Start() {
	go func() {
		ticker := time.NewTicker(time.Duration(int(math.Round(60.0/m.bpm))) * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-m.stopChan:
				return
			case <-ticker.C:
				m.logger.Debug("Metronome tick", slog.Int("BPM", int(m.bpm)))
			case newData := <-m.sd.updateChan:
				m.logger.Info("Metronome received updated data", slog.Any("data", newData))
			}
		}
	}()
}

func (m *Metronome) Stop() {
	close(m.stopChan)
	m.logger.Info("Metronome stopped")
}

type DataListener struct {
	sd       *SharedData
	stopChan chan struct{}
	logger   *slog.Logger
}

func NewDataListener(sd *SharedData, logger *slog.Logger) *DataListener {
	return &DataListener{
		sd:       sd,
		stopChan: make(chan struct{}),
		logger:   logger,
	}
}

func (dl *DataListener) Start() {
	go func() {
		for {
			select {
			case <-dl.stopChan:
				return
			case newData := <-dl.sd.updateChan:
				dl.logger.Info("DataListener received updated data", slog.Any("data", newData))
			}
		}
	}()
}

func (dl *DataListener) Stop() {
	close(dl.stopChan)
	dl.logger.Info("DataListener stopped")
}

func main() {
	var logLevel string
	flag.StringVar(&logLevel, "loglevel", "info", "set log level (info or debug)")
	flag.Parse()

	w := os.Stderr
	var logger *slog.Logger
	if logLevel == "debug" {
		logger = slog.New(tint.NewHandler(w, &tint.Options{
			Level:      slog.LevelDebug,
			TimeFormat: time.Kitchen,
		}))
	} else {
		logger = slog.New(tint.NewHandler(w, &tint.Options{
			Level:      slog.LevelInfo,
			TimeFormat: time.Kitchen,
		}))
	}
	slog.SetDefault(logger)

	sharedData := NewSharedData(logger)
	metronome := NewMetronome(sharedData, 80, logger)
	dataListener := NewDataListener(sharedData, logger)

	sharedData.Start()
	metronome.Start()
	dataListener.Start()

	quit := make(chan struct{})
	go func() {
		time.Sleep(30 * time.Second)
		close(quit)
	}()

	<-quit
	logger.Info("Stopping system...")
	sharedData.Stop()
	metronome.Stop()
	dataListener.Stop()
	logger.Info("System exited cleanly")
}
