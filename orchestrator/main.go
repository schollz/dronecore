package main

import (
	"flag"
	"log/slog"
	"math"
	"math/rand/v2"
	"os"
	"sync"
	"time"

	"github.com/hypebeast/go-osc/osc"
	"github.com/lmittmann/tint"
)

var oscSupercollider = osc.NewClient("127.0.0.1", 57120)

var mu sync.Mutex

func sendOSCMessage() {
	mu.Lock()
	defer mu.Unlock()
	msg := osc.NewMessage("/test")
	msg.Append(int32(1))
	msg.Append("Hello World")
	oscSupercollider.Send(msg)
}

func playMusicBox(note float32, velocity float32) {
	mu.Lock()
	defer mu.Unlock()
	msg := osc.NewMessage("/data")
	msg.Append("musicbox")
	msg.Append(note)
	msg.Append(velocity)
	oscSupercollider.Send(msg)
}

type UserData struct {
	booleanArray [32]bool
	knobArray    [5]float64
}

type SharedData struct {
	mu         sync.Mutex
	userData   UserData
	stopChan   chan struct{}
	updateChan chan UserData
	logger     *slog.Logger
}

func NewSharedData(logger *slog.Logger) *SharedData {
	s := &SharedData{
		userData: UserData{
			booleanArray: [32]bool{},
			knobArray:    [5]float64{},
		},
		stopChan:   make(chan struct{}),
		updateChan: make(chan UserData, 2),
		logger:     logger,
	}
	// start a OSC server to listen for data
	go func() {
		addr := "127.0.0.1:57121"
		d := osc.NewStandardDispatcher()
		d.AddMsgHandler("/data", func(msg *osc.Message) {
			// log the message
			logger.Debug("Received OSC message", slog.Any("message", msg))
			osc.PrintMessage(msg)
			// unmarshal into UserData
			var data UserData
			data.booleanArray = [32]bool{}
			data.knobArray = [5]float64{}
			for i := 0; i < 32; i++ {
				data.booleanArray[i] = msg.Arguments[i].(bool)
			}
			for i := 0; i < 5; i++ {
				data.knobArray[i] = float64(msg.Arguments[32+i].(float32))
			}
			// update shared data
			s.mu.Lock()
			s.userData = data
			s.mu.Unlock()
			for i := 0; i < 2; i++ {
				s.updateChan <- data
			}
		})

		server := &osc.Server{
			Addr:       addr,
			Dispatcher: d,
		}
		server.ListenAndServe()
	}()
	return s
}

func (sd *SharedData) Start() {
	go func() {
		for {
			select {
			case <-sd.stopChan:
				return
			}
		}
	}()
}

func (sd *SharedData) Stop() {
	close(sd.stopChan)
	close(sd.updateChan)
	sd.logger.Info("SharedData stopped")
}

const numSteps = 32

type Metronome struct {
	sd                       *SharedData
	bpm                      float64
	stopChan                 chan struct{}
	state                    UserData
	logger                   *slog.Logger
	notes                    [32][28]bool
	position                 int
	direction                int
	randomize                bool
	notesToPlay              [28]float32
	probabilityDisappearance float64
	firstTime                bool
}

func NewMetronome(sd *SharedData, bpm float64, logger *slog.Logger) *Metronome {
	// (Scale.major.degrees+(12*3))++(Scale.major.degrees+(12*4))++(Scale.major.degrees+(12*5))++(Scale.major.degrees+(12*6))
	m := &Metronome{
		sd:                       sd,
		bpm:                      bpm,
		stopChan:                 make(chan struct{}),
		logger:                   logger,
		notes:                    [32][28]bool{},
		position:                 0,
		direction:                1,
		randomize:                false,
		probabilityDisappearance: 0,
		firstTime:                true,
	}
	m.notesToPlay = [28]float32{
		36, 38, 40, 41, 43, 45, 47, 48, 50, 52, 53, 55, 57, 59, 60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83,
	}
	return m
}

func (m *Metronome) PrintNoteBoard() {
	for j := 27; j >= 0; j-- {
		for i := 0; i < numSteps; i++ {
			if m.notes[i][j] {
				print("X")
			} else {
				print("-")
			}
		}
		print("\n")
	}
}

func (m *Metronome) Start() {
	go func() {
		ticker := time.NewTicker(time.Duration(int(math.Round(60000000.0/m.bpm))) * time.Microsecond)
		defer ticker.Stop()
		for {
			select {
			case <-m.stopChan:
				return
			case <-ticker.C:
				m.logger.Debug("Metronome tick", slog.Int("BPM", int(m.bpm)))
				// play current note
				for i := 0; i < 28; i++ {
					if m.notes[m.position][i] {
						playMusicBox(m.notesToPlay[i], 90.0)
						if rand.Float64() < m.probabilityDisappearance {
							m.notes[m.position][i] = false
							m.PrintNoteBoard()
						}
					}
				}
				// update position
				if m.randomize {
					m.position = int(math.Floor(16 * rand.Float64()))
				} else {
					m.position += m.direction
				}
				if m.position >= numSteps {
					m.position -= numSteps
				}
				if m.position < 0 {
					m.position += numSteps
				}
			case newData := <-m.sd.updateChan:
				if m.firstTime {
					m.state = newData
					m.firstTime = false
					continue
				}
				for i := 0; i < 32; i++ {
					// 4 rows of 8
					row := i / 8
					col := i % 8
					if m.state.booleanArray[i] != newData.booleanArray[i] {
						m.logger.Info("Metronome received updated boolean", slog.Int("index", i), slog.Bool("value", newData.booleanArray[i]))
						if col > 0 {
							// recalculate index
							index := ((3 - row) * 7) + (col - 1)
							index = (index + 1) % 28
							m.notes[m.position][index] = !m.notes[m.position][index]
							m.PrintNoteBoard()
						}
					}
				}
				for i := 0; i < 5; i++ {
					if m.state.knobArray[i] != newData.knobArray[i] {
						m.logger.Info("Metronome received updated knob", slog.Int("index", i), slog.Float64("value", newData.knobArray[i]))
						switch i {
						case 0:
							m.probabilityDisappearance = newData.knobArray[i]
						}
					}
				}
				m.state = newData
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
				// case newData := <-dl.sd.updateChan:
				// 	dl.logger.Info("DataListener received updated data", slog.Any("data", newData))
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
	metronome := NewMetronome(sharedData, 90*4, logger)
	dataListener := NewDataListener(sharedData, logger)

	sharedData.Start()
	metronome.Start()
	dataListener.Start()

	quit := make(chan struct{})
	go func() {
		time.Sleep(3000 * time.Second)
		close(quit)
	}()

	<-quit
	logger.Info("Stopping system...")
	sharedData.Stop()
	metronome.Stop()
	dataListener.Stop()
	logger.Info("System exited cleanly")
}
