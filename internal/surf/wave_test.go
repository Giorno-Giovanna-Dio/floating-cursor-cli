package surf

import (
	"math"
	"testing"
)

func TestWaveYPeaksAndTroughs(t *testing.T) {
	peak := WaveY(0, math.Pi/2, 4)
	trough := WaveY(0, 3*math.Pi/2, 4)
	if math.Abs(peak-4) > 1e-9 {
		t.Fatalf("peak = %v, want 4", peak)
	}
	if math.Abs(trough+4) > 1e-9 {
		t.Fatalf("trough = %v, want -4", trough)
	}
}

func TestWaterRowStaysInBounds(t *testing.T) {
	for _, offset := range []float64{-40, -2, 0, 2, 40} {
		row := WaterRow(12, offset)
		if row < 1 || row > 10 {
			t.Fatalf("offset %v mapped to row %d, out of bounds", offset, row)
		}
	}
	if got := WaterRow(2, 0); got != 1 {
		t.Fatalf("tiny terminal row = %d, want 1", got)
	}
}

func TestSurferStateWrapsIntoLaps(t *testing.T) {
	width := 40
	sprite := 1
	span := width - sprite

	x, laps := SurferState(0, 1, width, sprite)
	if x != 0 || laps != 0 {
		t.Fatalf("start x,laps = %d,%d want 0,0", x, laps)
	}

	elapsedOneLap := float64(span) / cellsPerSecond
	x, laps = SurferState(elapsedOneLap, 1, width, sprite)
	if laps != 1 {
		t.Fatalf("after one lap: laps = %d, want 1 (x=%d)", laps, x)
	}

	xFast, lapsFast := SurferState(1, 2, width, sprite)
	xSlow, lapsSlow := SurferState(1, 1, width, sprite)
	if lapsFast < lapsSlow || (lapsFast == lapsSlow && xFast <= xSlow) {
		t.Fatalf("faster speed should advance further: fast=%d/%d slow=%d/%d", xFast, lapsFast, xSlow, lapsSlow)
	}
}

func TestSurferStateRejectsNonPositiveInputs(t *testing.T) {
	x, laps := SurferState(3, 0, 20, 0)
	if laps < 0 || x < 0 {
		t.Fatalf("unexpected negative state x=%d laps=%d", x, laps)
	}
	x, laps = SurferState(1, 1, 0, 1)
	if x != 0 || laps != 0 {
		t.Fatalf("zero width should stay put, got x=%d laps=%d", x, laps)
	}
}
